require 'nokogiri'
require 'erb'
require File.expand_path(File.dirname(__FILE__) + '/download')

class GrantSearch
   include ERB::Util
   
   SleepLength = 2
   DataRootDir = File.expand_path(File.dirname(__FILE__) + "/../data")
   
   
   def search(keywords, opps, search_id, verbose = false)
      # init search
      STDOUT.sync = true if verbose
      prep_dir search_id
      # prep result storage
      # get first page
      url =  "http://www.grants.gov/search/search.do?text=#{u(keywords)}&topagency=*&agency=*&eligible=*&fundInstrum=*&mode=Search&docs1=doc_open_checked#{opps==:all ? '&docs2=doc_close_checked&docs3=doc_archived_checked' : ''}&fundActivity=*&dates=*"
      page = 1
      filename = "#{page}.html"
      file = Download.get url, File.join(@search_dir, filename)
      doc = Nokogiri::HTML(file)
      # parse table into storage
      # get nextpage info
      pagelinks = doc.css('html body table tbody tr td table tbody tr td p a')
   puts pagelinks.inspect
      nextpagelink = pagelinks.last.href
      # loop remaining pages
      while !nextpagelink.empty?
         page += 1
         if verbose && page % 10 == 0
            print page, " "
         end
         sleep SleepLength
         # download page
         
         # parse table into storage
         # get nextpage info
      end
      # dump storage into csv
      # clean up temp files, or not
   end

private

   def prep_dir(search_id)
      @search_dir = File.join(DataRootDir, search_id)
      if Dir.exists?(@search_dir)
         raise "search_id '#{search_id}' is already in use"
      end
      Dir.mkdir @search_dir
   end

   def get_page(url, page, filename)
      
   end

end

=begin
gg = GrantSearch.new
gg.search "food", :all, "test1", true
=end

