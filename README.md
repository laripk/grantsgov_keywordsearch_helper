Grants.gov Keyword Search Helper
================================

It was brought to my attention by a good friend that the search facilities on Grants.gov are not so good. 
The keyword search always ORs your keywords together, even if you use AND or try to quote a phrase. 
On top of that it doesn't give the same count of results even if you run the exact same search 2 minutes apart.

So this is a little HTML scraper to suck down the results for a keyword search on Grants.gov into a CSV (Comma Separated Values) file. (CSV files are readable by the vast majority of spreadsheet and database programs.)

Installation
------------

1. Install Ruby, if you don't have it already. This tool was developed on Ruby 1.9.2.

  - Windows: Use the RubyInstaller: http://rubyinstaller.org/downloads/ Choose the 1.9.x installer, currently 1.9.2-p180. Run the installer, turn ON the check boxes to have the installer add ruby to your path and to associate the files with ruby.

  - Additional Ruby Install Options: http://www.ruby-lang.org/en/downloads/
  
  - Type `ruby --version` at the command line to verify that it has installed.

2. Download this project: 

  - Go to https://github.com/laripk/grantsgov_keywordsearch_helper 
  
  - Click the big Downloads button on the right and choose the appropriate compressed source bundle for your operating system. (Or use git, but if you thought of that you probably know how to do it.)
  
  - Unzip the download into a folder of your choosing.
  
3. You should now be able to go to the command line, switch to the folder where you put the source, type `ruby grant_search.rb` and see the introductory text from the program.

Notes on Usage
--------------

You run this tool by going to your command line, 
switching to the directory where you put the script, 
and entering `ruby grant_search.rb` at the command prompt.

It will ask for the name of a folder in which to save the search results, 
whether you want to search against all or only open grant opportunities, 
and what keywords you want to search with. 

Limited choice options `(Yes/[No])`, `(All/[Open])` have the default option marked with the square brackets.
In these cases it only looks at the first letter of what you type: 
If it matches the non-default option it goes with that; 
typing anything else (including leaving it blank) gives you the default option.

In the search folder, it will store all the HTML pages of the search results (eg, `1.html`, `2.html`, ...), 
a file called `search_options.txt` containing your search parameters, 
and the compiled results as `results.csv`. 
All of these files are marked read-only to prevent you from accidentally making changes 
to your reference copies. When you import the csv data, you will be creating a new file 
in the format of your spreadsheet or database, after all.

Note when importing the `results.csv` into your favorite spreadsheet or database program 
that there may be multiple entries in the `attachments` column, which is the last column. 
The attachments are separated by a `|` character, 
so if you want to spread them out into additional columns you can, 
just by telling your software about the additional separator during import 
(some software will let you split out the column as a separate step later). 
Don't forget to add headers for your extra columns.


