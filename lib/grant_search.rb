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
      file = get_page(url, page)
      doc = Nokogiri::HTML(File.read(file.path))
      # parse table into storage
      # get nextpage info
      next_page_link = get_next_page(doc)
   puts next_page_link
      # loop remaining pages
      while next_page_link
         page += 1
         if verbose && page % 10 == 0
            print page, " "
         end
         sleep SleepLength
         # download page
         file = get_page(next_page_link, page)
         doc = Nokogiri::HTML(File.read(file.path))
         # parse table into storage
         # get nextpage info
         next_page_link = get_next_page(doc)
   puts next_page_link
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
   
   def get_next_page(doc)
      links = doc.css('table tr td table tr td p a')
   puts doc.class, links.length
      nextlink = links.find do |node| 
         txt = node.children[0]
         txt.text == 'Next' if txt
      end
      if nextlink
         "http://www.grants.gov#{nextlink['href']}"
      else
         nil
      end
   end

   def get_page(url, page)
      filename = "#{page}.html"
      file = Download.get url, File.join(@search_dir, filename)      
   end

end

=begin

require '~/Projects/grantsgov_keywordsearch_helper/lib/grant_search'
gg = GrantSearch.new
gg.search "food", :open, "test3", true

doc = File.open('/Users/laripk/Projects/grantsgov_keywordsearch_helper/data/test2/1.html'){|file| Nokogiri::HTML(file)}


=end

