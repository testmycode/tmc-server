require 'fileutils'

namespace :comet do
  config_path = 'ext/tmc-comet/config.properties'
  namespace :config do
    desc "Writes #{config_path} based on site.yml"
    task :update do
      require './config/environment'

      File.open(config_path, 'wb') do |f|
        comet_server_config = SiteSetting.value('comet_server')
        f.puts('fi.helsinki.cs.tmc.comet.backendKey = ' + comet_server_config['backend_key'])
        f.puts('fi.helsinki.cs.tmc.comet.allowedServers = ' + comet_server_config['my_baseurl'])
      end
      puts "#{config_path} written thusly:"
      puts File.read(config_path)
    end

    desc "Removes #{config_path}"
    task :clean do
      FileUtils.rm_f(config_path)
    end
  end
end
