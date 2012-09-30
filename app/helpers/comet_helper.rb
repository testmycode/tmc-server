require 'site_setting'

module CometHelper
  def comet_js_url(script_name)
    SiteSetting.value('comet_server')['url'].gsub(/\/+$/, '') + '/js/' + script_name
  end

  def comet_server_url_meta_tag
    tag :meta, :name => 'comet_server_baseurl', :content => CometServer.get.client_url
  end

  def comet_tmc_baseurl_meta_tag
    tag :meta, :name => 'comet_tmc_baseurl', :content => CometServer.get.webserver_baseurl
  end
end
