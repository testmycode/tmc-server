require 'rest_client'

# Represents the configured tmc-comet server.
#
# Provides methods for publishing comet events.
class CometServer
  def self.get
    conf = SiteSetting.value('comet_server')
    @instance ||= CometServer.new(conf['url'], conf['backend_key'], conf['my_baseurl'])
  end

  def initialize(comet_baseurl, key, webserver_baseurl)
    @comet_baseurl = comet_baseurl.gsub(/\/+$/, '')
    @key = key
    @webserver_baseurl = webserver_baseurl
  end

  def url
    @comet_baseurl + '/'
  end

  def publish_url
    @comet_baseurl + '/synchronous/publish'
  end

  def client_url
    @comet_baseurl.gsub(/\/+$/, '') + '/comet'
  end

  attr_reader :webserver_baseurl

  def try_publish(channel, msg)
    begin
      publish(channel, msg)
      true
    rescue
      ::Rails.logger.error "Failed to publish to #{publish_url}: #{$!}"
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
    RestClient.post(publish_url, params)
  end
end