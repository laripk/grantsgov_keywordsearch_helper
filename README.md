Grants.gov Keyword Search Helper
================================

It was brought to my attention by a good friend that the search facilities on Grants.gov are not so good. The keyword search always ORs your keywords together, even if you use AND or try to quote a phrase. On top of that it doesn't give the same count of results even if you run the exact same search 2 minutes apart.

So this is a little HTML scraper to suck down the results for a keyword search on Grants.gov into a CSV (Comma Separated Values) file. (CSV files are readable by the vast majority of spreadsheet and database programs.)

-------------------------------------------------------------

Notes on Usage
--------------

See Installation Notes, ...

You run it by ...

It will ask for ... 

In the search folder, it will store all the HTML pages of the search results (eg, `1.html`, `2.html`, ...) and it will store the compiled results as `results.csv`.

Note when importing the `results.csv` into your favorite spreadsheet or database program that there may be multiple entries in the `attachments` column, which is the last column. The attachments are separated by a '|' character, so if you want to spread them out into additional columns you can, just by telling your software about the additional separator during import (some software will let you split out the column as a separate step later). Just don't forget to add headers for your extra columns.


