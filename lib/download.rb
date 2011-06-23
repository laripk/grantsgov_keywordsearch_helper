require 'open-uri'

class Download
  def self.get(url, filename)
    open(filename, 'wb') do |f|
      f << open(url).read
    end
  end
end
