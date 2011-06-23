require 'open-uri'

class Download
   @@cookie = '' # this minimal cookie-store assumes we're only ever visiting one site
   
   def self.get(url, filename)
      open(filename, 'wb') do |f|
         pg = open(url, 
            :read_timeout => 300,
            'Cookie' => @@cookie,
            'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_5_8) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.20 Safari/535.1'
         )
   puts pg.meta.inspect
         @@cookie = pg.meta['set-cookie'] || @@cookie
   puts @@cookie
         f << pg.read
      end
   end
end
