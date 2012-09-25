require 'rest_client'

class CometServer
  def self.get
    conf = SiteSetting.value('comet_server')
    @instance ||= CometServer.new(conf['url'], conf['backend_key'], conf['my_baseurl'])
  end

  def initialize(comet_baseurl, key, my_baseurl)
    @url = comet_baseurl.gsub(/\/+$/, '') + '/synchronous/publish'
    @key = key
    @my_baseurl = my_baseurl
  end

  attr_reader :url

  def try_publish(channel, msg)
    begin
      publish(channel, msg)
      true
    rescue
      ::Rails.logger.error "Failed to publish to #{@url}: #{$!}"
      false
    end
  end

  def publish(channel, msg)
    params = {
      :channel => channel,
      :data => msg.to_json,
      :serverBaseUrl => @my_baseurl,
      :backendKey => @key
    }
    ::Rails.logger.info "Posting to tmc-comet: #{params.inspect}"
    RestClient.post(@url, params)
  end
end