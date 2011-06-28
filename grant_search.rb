require 'nokogiri'
require 'erb'
require 'active_support/core_ext/string'
require 'csv'
require 'open-uri'


class App
   VERSION = '0.1.0'
   COPYRIGHT = '2011 by Lari P. Kirby'
   
   def run
      display_intro
      running_count = 0
      return running_count unless do_again?(true)
      @gs = GrantSearch.new
      begin
         search_folder = get_search_folder
         opps = get_which_opps
         keywords = get_keywords
         count = @gs.search(keywords, opps, search_folder)
         puts "\nFound #{count} records."
         running_count += count
      end while do_again?
      running_count
   end
   
protected

   def do_again?(first_time = false)
      prompt = "\Do you want to run a#{first_time ? '' : 'nother'} search? (Yes/[No])"
      answer = ask(prompt) 
      %w(Y y T t).include?(answer[0])
   end
   
   def display_intro
      msg = <<-USAGE
      This is grantsgov_keywordsearch_helper version #{VERSION},
      copyright #{COPYRIGHT}.
       
      It is a tool that will run a keyword search on the grants.gov site,
      save all pages of the results, and compile the results into a CSV file
      ready to be imported into your favorite spreadsheet or database program.
      USAGE
      puts msg
   end
   
   def get_search_folder
      banner = <<-HERE
      
      Please enter a name for this search. This will be used as a directory name 
      in the data folder where this script resides, and all your search results
      will be saved here. It needs to not already exist.
      HERE
      prompt = "search folder name>"
      puts banner
      begin
         answer = ask(prompt)
         ans_ok = @gs.dir_ok?(answer)
         if !ans_ok
            puts "'#{answer}' is not available as a new search folder name. Please try again."
         end
      end until ans_ok 
      answer
   end
   
   def get_which_opps
      prompt = "Do you want to search All or only Open opportunities? (All/[Open])"
      answer = ask(prompt)
      which_opps = if %w(A a).include?(answer[0])
         :all
      else
         :open
      end
   end
   
   def get_keywords
      prompt = "What keywords do you want to search?"
      answer = ask(prompt)
   end
   
   def ask(prompt)
      print "\n#{prompt} "
      answer = gets
      answer.strip
   end
end


class GrantSearch
   include ERB::Util
   
   SleepLength = 2
   DataRootDir = File.expand_path(File.dirname(__FILE__) + "/data")
   LinkRoot = 'http://www.grants.gov'
   
   ColDate = 0
   ColTitle = 1
   ColAgency = 2
   ColFundNum = 3
   ColAttach = 4
   RecordsPerPage = 20
   
   
   def search(keywords, opps, search_folder, verbose = true)
      # init search
      if verbose
         STDOUT.sync = true
         print "\nDownload progress (even pages)... "
      end
      prep_dir search_folder
      save_search_options keywords, opps
      init_results

      # get first page
      url =  "#{LinkRoot}/search/search.do?text=#{url_encode(keywords)}&topagency=*&agency=*&eligible=*&fundInstrum=*&mode=Search&docs1=doc_open_checked#{opps==:all ? '&docs2=doc_close_checked&docs3=doc_archived_checked' : ''}&fundActivity=*&dates=*"
      page = 1
      doc = get_page(url, page)

      parse_table doc
      expected_record_count, expected_page_count = get_count(doc)
      if verbose && expected_page_count > 1
         print "(expecting #{expected_page_count} pages) "
      end
      next_page_link = get_next_page(doc)
      while next_page_link
         page += 1
         if verbose && page % 2 == 0
            print page, ' '
         end
         sleep SleepLength
         doc = get_page(next_page_link, page)
         parse_table doc
         next_page_link = get_next_page(doc)
      end
      if verbose
         puts 'finishing up...'
      end
      # dump storage into csv
      output_results
      @results.length
   end

   def dir_ok?(search_folder)
      @search_dir = File.join(DataRootDir, search_folder)
      !Dir.exists?(@search_dir)
   end

private
# attr_reader :results

   def save_search_options(keywords, opps)
      open(File.join(@search_dir, 'search_options.txt'), 'wt:UTF-8') do |file|
         file << "Keywords:\n\t#{keywords}\n"
         file << "Which Opportunities:\n\t"
         if opps == :all
            file << "All\n"
         else
            file << "Open\n"
         end
         file.chmod 0o444
      end
   end

   def init_results
      @results = []
   end

   def prep_dir(search_folder)
      unless dir_ok?(search_folder)
         raise "search_folder '#{search_folder}' is already in use"
      end
      Dir.mkdir(DataRootDir) unless Dir.exists?(DataRootDir)
      Dir.mkdir @search_dir
   end
   
   def get_next_page(doc)
      links = doc.css('table tr td table tr td p a')
      nextlink = links.find do |node| 
         txt = node.children[0]
         txt.text == 'Next' if txt
      end
      if nextlink
         "#{LinkRoot}#{nextlink['href']}"
      else
         nil
      end
   end

   def get_count(doc)
      count_area = doc.css('tr:nth-child(3) p')
      if count_area && count_area.length == 2
         count_para = count_area[1].text.split(' ')
         record_count = count_para[-1].to_i
         page_count = record_count / RecordsPerPage + 
                     (record_count % RecordsPerPage > 0 ? 1 : 0)
         [record_count, page_count]
      else
         [0, 1]
      end
   end

   def get_page(url, page)
      filename = "#{page}.html"
      file = Download.get url, File.join(@search_dir, filename)
      doc = Nokogiri::HTML(File.read(file.path))
   end

   def clean_text(str)
      str = str.force_encoding("Windows-1252")
      s = strip_garbage_win_chars(str)
      str = s.force_encoding("Windows-1252").encode("UTF-8")
      s = strip_annoying_unicode(str)
      s = ActiveSupport::Inflector.transliterate(s)
      s.strip
   end
   
   def strip_garbage_win_chars(str)
      raise "strip_garbage_win_chars requires a Windows-1252 string, not #{str.encoding}" unless str.encoding.to_s == "Windows-1252"
      s = ''
      str.each_byte do |c|
         case c
         when 0x81, 0x8D, 0x8F, 0x90, 0x9D
            # garbage character that cannot be translated to UTF-8
            # drop it
         else
            s << c
         end
      end
      s
   end
   
   def strip_annoying_unicode(str)
      raise "strip_annoying_unicode requires a UTF-8 string, not #{str.encoding}" unless str.encoding.to_s == "UTF-8"
      s = ''
      str.codepoints do |c|   # ActiveSupport::Multibyte::Unicode.g_unpack(str).each
         case c
         when 160
            s << ' '
         when 194
            # the re-encoding is not bundling this prefix code with its suffix properly, 
            # so just drop it
         when 0x02C6
            s << '^'
         when 0x02DC
            s << '~'
         when 0x2002..0x200B
            s << ' '
         when 0x2010..0x2014
            s << '-'
         when 0x2018..0x201B, 0x2039..0x203A
            s << "'"
         when 0x201C..0x201F 
            s << '"'
         when 0x2020..0x2022
            s << '*'
         when 0x2026
            s << '...'
         when 0x2030
            s << '0/00' # per mille sign
         when 0x20AC
            s << 'Euro'
         when 0x2122
            s << 'TM'
         else
            # warn "character #{c} not translated" if c > 255
            s << c.chr(Encoding::UTF_8)
         end
      end
      s
   end

   def parse_table(doc)
      table = doc.css('table:nth-child(2)')[0]
      if table
         rows = table.css('tr')
         (1..(rows.length-1)).each do |i|
            row = rows[i].css('td')
            @results << parse_row(row)
         end
      end
   end
   
   def parse_row(row)
      result_row = {}
      
      result_row[:date] = clean_text(row[ColDate].text)
      result_row[:agency] = clean_text(row[ColAgency].text)
      result_row[:fund_num] = clean_text(row[ColFundNum].text)
      
      atts = row[ColAttach].css('a')
      if atts.length > 0
         result_row[:attachments] = atts.map do |att|
            a = {}
            a[:descrip] = clean_text(att.text)
            if a[:descrip] == ''
               a[:descrip] = 'Unnamed Attachment'
            end
            a[:link] = "#{LinkRoot}#{att['href']}"
            a
         end
      else
         result_row[:attachments] = []
      end
      
      title = row[ColTitle].css('a')[0]
      result_row[:title] = clean_text(title.text)
      
      link = title['href'].sub(/;jsessionid=.+\?/, '?')
      result_row[:opp_link] = "#{LinkRoot}#{link}"
      result_row[:opp_id] = /\boppId=(\d+)\b/.match(link)[1]
   
      result_row
   end

   def output_results
      open(File.join(@search_dir, 'results.csv'), 'wt:UTF-8') do |file|
         file << csv_results_header
         @results.each do |row|
            file << csv_result_row(row)
         end
         file.chmod 0o444
      end
   end
   
   def csv_results_header
      "Open Date,Opportunity Id,Opportunity Title,Opportunity Link,Agency,Funding Number,Attachments\n"
   end
   
   def csv_result_row(row)
      r = []
      r << row[:date]
      r << row[:opp_id]
      r << row[:title]
      r << "#{row[:opp_link]} "
      r << row[:agency]
      r << row[:fund_num]
      r << row[:attachments].map{|att| "#{att[:descrip]} #{att[:link]} " }.join('|')
      r.to_csv
   end
   
end


class Download
   @@cookie = '' # this minimal cookie-store assumes we're only ever visiting one site
   
   def self.get(url, filename)
      open(filename, 'wb') do |f|
         pg = open(url, 
            :read_timeout => 300,
            'Cookie' => @@cookie,
            'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_5_8) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.20 Safari/535.1'
         )
         @@cookie = pg.meta['set-cookie'] || @@cookie
         f << pg.read
         f.chmod 0o444
         f
      end
   end
end


app = App.new
total = app.run
puts "A grand total of #{total} records found during this session."

