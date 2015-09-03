require 'fileutils'
require 'system_commands'

class RemoteSandboxForTesting
  @server_pids = nil
  @result_queue = nil
  @server_ports = nil
  @host = 'http://localhost'

  def self.server_ports
    # Currently just one server. Running multiple server webapps on the same machine is problematic.
    # Conflicting Squid files and ports etc.
    @server_ports ||= [FreePorts.take_next]
  end

  # Runs a submission and asserts the run succeeded, then calls SandboxResultsSaver.
  def self.run_submission(submission)
    submission.randomize_secret_token if submission.secret_token.nil?

    sandbox = RemoteSandbox.all.first
    sandbox.send_submission(submission, result_queue.receiver_url)
    results = result_queue.pop
    SandboxResultsSaver.save_results(submission, results)
  end

  # Allows tests to be run w/o root by using an external sandbox.
  def self.use_server_at(host, port)
    @host = host
    @server_ports = [port].flatten
  end

  def self.init_servers_as_root!(actual_user, actual_group)
    fail 'Root helper already started' if @root_helper
    fail 'init_servers_as_root! should be called as root' if Process::Sys.geteuid != 0

    server_ports.each do |port|
      copy_server_instance(port, actual_user, actual_group)
    end

    @root_helper = RootHelper.new
    @root_helper.send_command('START SERVER ' + server_ports.join(','))
  end

  def self.init_stubs!
    RemoteSandbox.stub(:all) do
      server_ports.map { |port| RemoteSandbox.new("#{@host}:#{port}/") }
    end
  end

  def self.cleanup_after_all_tests!
    @root_helper.stop if @root_helper
    @root_helper = nil

    result_queue.cleanup!
    @result_queue = nil
  end

  private

  def self.result_queue
    @result_queue ||= SubmissionResultReceiver.new
  end

  def self.copy_server_instance(port, actual_user, actual_group)
    instance_dir = "#{::Rails.root}/tmp/test-sandbox-server/#{port}"
    maven_cache_dir = "#{::Rails.root}/tmp/test-maven-cache" # This we won't delete each time

    FileUtils.mkdir_p(maven_cache_dir)
    SystemCommands.sh!('chown', '-R', actual_user, maven_cache_dir)
    SystemCommands.sh!('chgrp', '-R', actual_group, maven_cache_dir)

    FileUtils.rm_rf instance_dir
    FileUtils.mkdir_p instance_dir

    source = "#{::Rails.root}/ext/tmc-sandbox"
    FileUtils.ln_s "#{source}/misc", "#{instance_dir}/misc"
    FileUtils.ln_s "#{source}/uml", "#{instance_dir}/uml"
    FileUtils.cp_r "#{source}/web", instance_dir

    FileUtils.rm_rf "#{instance_dir}/web/work"
    FileUtils.mkdir_p "#{instance_dir}/web/work"
    FileUtils.rm_rf "#{instance_dir}/web/log"
    FileUtils.mkdir_p "#{instance_dir}/web/log"
    FileUtils.rm_rf "#{instance_dir}/web/lock"
    FileUtils.mkdir_p "#{instance_dir}/web/lock"

    File.open("#{instance_dir}/web/site.yml", 'w') do |f|
      f.puts "tmc_user: #{actual_user}"
      f.puts "tmc_group: #{actual_group}"
      f.puts "http_port: #{port}"

      # Enable maven cache. It makes tests go faster when we run them often,
      # and the cache gets some more testing too.
      f.puts 'plugins:'
      f.puts '  maven_cache:'
      f.puts '    enabled: true'
      f.puts "    alternate_work_dir: #{maven_cache_dir}"
    end
  end
end

RSpec.configure do |config|
  config.before :each do
    RemoteSandboxForTesting.init_stubs!
  end

  config.after :suite do
    RemoteSandboxForTesting.cleanup_after_all_tests!
  end
end
