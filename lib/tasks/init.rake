require 'ruby_init_script'
require 'etc'

namespace :background_daemon do
  namespace :init do
    DEFAULT_NAME = 'tmc-background-daemon'

    def init_script(name = nil)
      name ||= DEFAULT_NAME
      RubyInitScript.new({
        name: name,
        short_description: 'TMC background daemon',
        executable_path: 'script/background_daemon',
        user: Etc.getpwuid(File.stat(::Rails::root).uid).name
      })
    end

    desc "Install background daemon init script. RVM-compatible. Optional arg: script name."
    task :install, [:name] do |t, args|
      init_script(args[:name]).install
    end

    desc "Preview background daemon init script."
    task :preview do
      script = init_script.script_source
      puts
      puts "-"*80
      puts script
      puts "-"*80
      puts
    end

    desc "Uninstall init script. Optional arg: script name."
    task :uninstall, :name do |t, args|
      init_script(args[:name]).uninstall
    end

    desc "Reinstall init script. Optional arg: script name."
    task :reinstall, [:name] => [:uninstall, :install]
  end
end

namespace :comet do
  namespace :init do
    desc "Install tmc-comet init script. Optional arg: port number (defaults to 8080)."
    task :install, [:port] do |t, args|
      if args[:port]
        system("ext/tmc-comet/initscripts/install.sh #{args[:port]}")
      else
        system("ext/tmc-comet/initscripts/install.sh")
      end
    end

    task :uninstall do
      system('ext/tmc-comet/initscripts/uninstall.sh')
    end

    task reinstall: [:uninstall, :install]
  end
end

namespace :init do
  initables = [:background_daemon, :comet]
  desc "Installs all initscripts"
  task install: initables.map {|initable| "#{initable}:init:install" }
  desc "Uninstalls all initscripts"
  task uninstall: initables.map {|initable| "#{initable}:init:uninstall" }
  desc "Reinstalls all initscripts"
  task reinstall: initables.map {|initable| "#{initable}:init:reinstall" }
end
