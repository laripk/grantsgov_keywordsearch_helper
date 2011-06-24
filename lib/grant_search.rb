require 'nokogiri'
require 'erb'
# require 'active_support'
require 'active_support/core_ext/string'
# require 'active_support/multibyte'
require File.expand_path(File.dirname(__FILE__) + '/download')

class GrantSearch
   include ERB::Util
   # include ActiveSupport::Inflector
   
   SleepLength = 2
   DataRootDir = File.expand_path(File.dirname(__FILE__) + "/../data")
   LinkRoot = 'http://www.grants.gov'
   
   ColDate = 0
   ColTitle = 1
   ColAgency = 2
   ColFundNum = 3
   ColAttach = 4
   
   
   def search(keywords, opps, search_id, verbose = false)
      # init search
      STDOUT.sync = true if verbose
      prep_dir search_id
      init_results

      # get first page
      url =  "#{LinkRoot}/search/search.do?text=#{url_encode(keywords)}&topagency=*&agency=*&eligible=*&fundInstrum=*&mode=Search&docs1=doc_open_checked#{opps==:all ? '&docs2=doc_close_checked&docs3=doc_archived_checked' : ''}&fundActivity=*&dates=*"
      page = 1
      doc = get_page(url, page)

      parse_table doc
      next_page_link = get_next_page(doc)
      while next_page_link
         page += 1
         if verbose && page % 5 == 0
            print page, " "
         end
         sleep SleepLength
         doc = get_page(next_page_link, page)
         parse_table doc
         next_page_link = get_next_page(doc)
      end
      # dump storage into csv
   puts @results.length
      # clean up temp files, or not
   end

# private
attr_reader :results

   def init_results
      @results = []
   end

   def prep_dir(search_id)
      @search_dir = File.join(DataRootDir, search_id)
      if Dir.exists?(@search_dir)
         raise "search_id '#{search_id}' is already in use"
      end
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

   def get_page(url, page)
      filename = "#{page}.html"
      file = Download.get url, File.join(@search_dir, filename)
      doc = Nokogiri::HTML(File.read(file.path))
   end

   def clean_text(str)
puts "in", str
      str = str.force_encoding("Windows-1252")
puts str
      s = strip_garbage_win_chars(str)
puts s
      str = s.force_encoding("Windows-1252").encode("UTF-8")
      s = strip_annoying_unicode(str)
      s = ActiveSupport::Inflector.transliterate(s)
      s.strip
   end
   
   def strip_garbage_win_chars(str)
      raise "strip_garbage_win_chars requires a Windows-1252 string, not #{str.encoding}" unless str.encoding.to_s == "Windows-1252"
      s = ''
      str.each_byte do |c|
   print ' ', c
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
            # (I doubt there are many A-circumflexes in the database)
         when 0x201C..0x201F # because curly quotes annoy me
            s << '"'
         when 0x2018..0x201B # because curly quotes annoy me
            s << "'"
         else
            warn "character #{c} not translated" if c > 127
            s << c
         end
      end
      s
   end

   def parse_table(doc)
      rows = doc.css('table:nth-child(2)')[0].css('tr')
      (1..(rows.length-1)).each do |i|
         row = rows[i].css('td')
         @results << parse_row(row)
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
   
   puts result_row.inspect
      result_row
   end

end

=begin

require '~/Projects/grantsgov_keywordsearch_helper/lib/grant_search'
gg = GrantSearch.new
gg.search "food borne illness", :open, "test6", true



require 'nokogiri'


require '~/Projects/grantsgov_keywordsearch_helper/lib/grant_search'

doc = File.open('/Users/laripk/Projects/grantsgov_keywordsearch_helper/data/test6/8.html'){|file| Nokogiri::HTML(file)}
doc.class

gg = GrantSearch.new
gg.init_results
gg.parse_table doc


gg.results[1] # garbage chars (binary attach interpreted as plain text)

gg.results[6] # multiple attachments

gg.results[9] # no attachments


doc = File.open('/Users/laripk/Projects/grantsgov_keywordsearch_helper/data/test5/5.html'){|file| Nokogiri::HTML(file)}

gg.init_results
gg.parse_table doc

gg.results[7] # curly quote

gg.results[6] # multiple attachments, one with curly quote




nb = "-\xC2\xA0-"


=end




