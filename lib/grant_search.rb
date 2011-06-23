require 'nokogiri'
require 'erb'
require File.expand_path(File.dirname(__FILE__) + '/download')

class GrantSearch
   include ERB:Util
   
   SleepLength = 2
   DataRootDir = File.expand_path(File.dirname(__FILE__) + "/../data")
   
   
   def search(keywords, opps, search_id, verbose = false)
      # init search
      STDOUT.sync = true if verbose
         # prep dir
         search_dir = File.join(DataRootDir, search_id)
         if Dir.exists?(search_dir)
            raise "search_id '#{search_id}' is already in use"
         end
         Dir.mkdir search_dir
         # prep result storage
      # get first page
      url =  "http://www.grants.gov/search/search.do?text=#{u(keywords)}&topagency=*&agency=*&eligible=*&fundInstrum=*&mode=Search&docs1=doc_open_checked#{opps==:all ? '&docs2=doc_close_checked&docs3=doc_archived_checked' : ''}&fundActivity=*&dates=*"
      page = 1
      filename = "#{page}.html"
      file = Download.get url, File.join(search_dir, filename)
      doc = Nokogiri::Slop(file)
         # parse table into storage
         # get nextpage info
      # loop remaining pages
      begin
         page += 1
         if verbose && page % 10 == 0
            print page, " "
         end
         sleep SleepLength
         # post & download page
         # parse table into storage
         # get nextpage info
      end while !nextpagelink.empty?
      # dump storage into csv
      # clean up temp files, or not
   end
   
   
   
   


   
end


# http://www07.grants.gov/search/search.do?text=a+OR+the+OR+in+OR+an+OR+and+OR+if+OR+off+OR+or&topagency=*&agency=*&eligible=*&fundInstrum=*&mode=Search&docs1=doc_open_checked&fundActivity=*&dates=*&mode=PAGECHANGE&pageNum=2

