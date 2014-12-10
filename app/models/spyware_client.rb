require 'site_setting'
require 'uri'
require 'net/http'
require 'zlib'

class SpywareClient
  def self.send_data_to_any(data, username, session_id)
    client = self.open
    if client
      client.send_data(data, username, session_id)
    end
  end

  def self.open
    urls = SiteSetting.value('spyware_servers')
    unless urls.empty?
      url = urls[Random.rand(0...(urls.size))]
      SpywareClient.new(url)
    end
  end

  def initialize(url)
    @url = url
  end

  def send_data(data, username, session_id)
    compressed_data = ""
    gz = Zlib::GzipWriter.new(StringIO.new(compressed_data), Zlib::DEFAULT_COMPRESSION, Zlib::DEFAULT_STRATEGY)
    begin
      gz.write(data.to_s)
    ensure
      gz.close
    end

    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path)
    request['X-Tmc-Version'] = '1'
    request['X-Tmc-Username'] = username
    request['X-Tmc-Session-Id'] = session_id
    request.body = compressed_data
    response = http.request(request)
    response.value # raise if not successful
    nil
  end
end
