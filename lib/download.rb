require 'open-uri'

class Download
  def self.get(url, filename)
    open(filename, 'wb', 
      :read_timeout => 300,
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_5_8) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.20 Safari/535.1'
    ) do |f|
      f << open(url).read
    end
  end
end
