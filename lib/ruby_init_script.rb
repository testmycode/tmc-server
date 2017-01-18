require 'shellwords'
require 'system_commands'
require 'erb'
require 'pathname'

# Manages a sysv init script that calls a Ruby program that accepts the standard start|stop|restart|status parameters.
# Compatible with RVM.
class RubyInitScript
  def initialize(options = {})
    @options = default_options.merge(options)
    preprocess_options
    check_options
  end

  def default_options
    {
      name: nil,
      erb_path: File.dirname(File.realpath(__FILE__)) + '/ruby_init_script/initscript.erb',
      rails_env: 'production',
      working_dir: ::Rails.root,
      executable_path: nil,
      short_description: nil,
      user: 'root'
    }
  end

  def script_source
    # TODO: This breaks if rvm is not installed
    rvm_current = `rvm current`
    if $?.success?
      puts 'Using RVM.'
      rvm_current.strip!
      ruby_path = rvm_info[rvm_current]['binaries']['ruby']
      env = rvm_info[rvm_current]['environment']
    else
      puts "Not using RVM. Don't forget to invoke this with rvmsudo if you use RVM."
      ruby_path = `which ruby`.chomp
      env = {}
    end

    if @options[:rails_env]
      env['RAILS_ENV'] = @options[:rails_env]
    end

    def get_binding(_name, _working_dir, _executable_path, _ruby_path, _user, _env)
      binding
    end

    erb = ERB.new(File.read(@options[:erb_path]))

    b = get_binding(
      init_script_full_name,
      @options[:working_dir],
      @options[:executable_path],
      ruby_path,
      @options[:user],
      env
    )

    erb.result(b)
  end

  def install
    script = script_source

    puts "Installing into #{init_script_path}"
    File.open(init_script_path, 'w') { |f| f.write(script) }
    system("chmod a+x #{Shellwords.escape(init_script_path)}")

    puts 'Setting to start/stop by default'
    system("update-rc.d #{init_script_full_name} defaults 90 10")
  end

  def uninstall
    system("update-rc.d -f #{init_script_full_name} remove")
    if File.exist?(init_script_path)
      File.delete(init_script_path)
    else
      puts "#{init_script_path} doesn't exist."
    end
  end

  def init_script_full_name
    @options[:name]
  end

  def init_script_path
    "/etc/init.d/#{init_script_full_name}"
  end

  def short_description
    @options[:short_description] || init_script_full_name
  end

  private

  def preprocess_options
    @options.each_key do |k|
      if @options[k].is_a? Pathname
        @options[k] = @options[k].to_s
      end
    end
  end

  def check_options
    fail ':name required' unless @options[:name]
    fail ':erb_path required' unless @options[:erb_path]
    fail ':working_dir required' unless @options[:working_dir]
    fail ':executable_path required' unless @options[:executable_path]
  end

  def rvm_info
    @rvm_info ||= begin
      output = `rvm info 2>/dev/null` # We silence the "RVM is not a function" warning on stderr.
      # This can happen if one uses `sudo -i -u tmc` and then does `rvmsudo rvm info`.
      potential_warning = <<EOS
You need to change your terminal emulator preferences to allow login shell.
Sometimes it is required to use `/bin/bash --login` as the command.
Please visit https://rvm.io/integration/gnome-terminal/ for a example.
EOS
      output = output.sub(potential_warning, '')
      YAML.load(output)
    end
  end
end
