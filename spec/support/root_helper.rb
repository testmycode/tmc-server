require 'fileutils'

class RootHelper
  def initialize
    raise "Should be root" if Process::Sys.geteuid != 0
    p1_in, p1_out = IO.pipe
    p2_in, p2_out = IO.pipe
    @pid = Process.fork do
      $stdin.reopen("/dev/null")
      signals = ["TERM", "INT", "HUP", "USR1", "USR2"]
      signals.each do |sig|
        Signal.trap(sig) do
          puts "Root helper exiting (SIG#{sig})"
          exit!(1)
        end
      end

      Process::Sys.setreuid(0, 0)
      p1_out.close
      p2_in.close
      @pipe_in = p1_in
      @pipe_out = p2_out

      @server_pids = []

      main_loop

      exit!(0)
    end
    p1_in.close
    p2_out.close
    @pipe_in = p2_in
    @pipe_out = p1_out
  end

  def stop
    raise "Not started" if !@pid
    @pipe_out.write("STOP\n")
    @pipe_in.read
    @pipe_out.close
    @pipe_in.close
    Process.waitpid(@pid)
    @pid = @pipe_in = @pipe_out = nil
  end

  def send_command(command)
    @pipe_out.write("#{command}\n")
    response = @pipe_in.readline.strip
    if response =~ /^FAIL (.*)$/
      raise "#{$1} (from RootHelper)"
    end
    response
  end

private
  def main_loop
    begin
      command = @pipe_in.readline.strip
      begin
        response = execute_command(command)
      rescue
        response = "FAIL: #{$!.message.gsub("\n", " ")}"
        debug(response)
      end
      @pipe_out.write("#{response}\n") unless response.blank?
    end while command != "STOP"
  end

  def execute_command(command)
    if command =~ /^START SERVERS? (\d+(?:\s*,\s*\d+)*)$/
      raise "Servers already started" if !@server_pids.empty?
      ports = $1.split(",").map(&:strip).map(&:to_i)
      start_servers(ports)
      "OK"
    elsif command == 'STOP'
      stop_all_servers
      "BYE"
    else
      raise "Invalid command: #{command}"
    end
  end

  def start_servers(ports)
    @server_pids = ports.map {|port| start_server(port.to_i) }
    sleep 5 # Wait for servers to start. Haxy, slow, error-prone :(
  end

  def stop_all_servers
    debug("Starting stopping all servers (pids #{@server_pids.join(',')})")
    for server_pid in @server_pids
      Process.kill("TERM", server_pid)
      Process.waitpid(server_pid)
    end
    @server_pids = []
  end

private
  def start_server(port)
    debug("Starting server #{port}")

    instance_dir = "#{servers_parent_dir}/#{port}"
    raise "Server directory not created" if !File.exist?(instance_dir)

    Process.fork do
      begin
        $stdin.reopen("/dev/null", 'r')
        $stdout.reopen("#{instance_dir}/web/work/master.log", 'w')
        $stderr.reopen($stdout)
        Dir.chdir "#{instance_dir}/web"
        ENV.delete 'BUNDLE_GEMFILE'
        Process.exec("ruby ./webapp.rb run")
      rescue
        puts "Error starting webapp.rb: " + e.class.to_s + ": " + e.message
      ensure
        exit!(1)
      end
    end
  end

  def servers_parent_dir
    "#{::Rails.root}/tmp/test-sandbox-server"
  end

  def debug(msg)
    #puts "Root helper: #{msg}"
  end
end