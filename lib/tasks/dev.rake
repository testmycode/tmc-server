namespace :dev do
  namespace :comet do
    config_path = 'tmp/development/tmc-comet-config.properties'

    desc "Compiles and configures ext/tmc-comet for development."
    task :configure => ['comet:compile'] do
      require './config/environment'
      FileUtils.mkdir_p('tmp/development')

      File.open(config_path, 'wb') do |f|
        comet_server_config = SiteSetting.value('comet_server')
        f.puts('fi.helsinki.cs.tmc.comet.backendKey = ' + comet_server_config['backend_key'])
        f.puts('fi.helsinki.cs.tmc.comet.allowedServers = ' + comet_server_config['my_baseurl'])
      end
    end

    desc "Starts tmc-comet in this terminal"
    task :run => :configure do
      abs_config_path = File.absolute_path(config_path)
      Dir.chdir('ext/tmc-comet') do
        system("./tmc-comet-server.sh #{abs_config_path}")
      end
    end
  end
end
