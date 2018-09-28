# frozen_string_literal: true

require 'site_setting'

module CometHelper
  def comet_js_url(script_name)
    SiteSetting.value('comet_server')['url'].gsub(/\/+$/, '') + '/js/' + script_name
  end

  def comet_server_baseurl
    CometServer.get.client_url
  end

  def comet_tmc_baseurl
    CometServer.get.webserver_baseurl
  end
end
