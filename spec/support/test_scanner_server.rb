
# We speed up tests considerably by only loading the javac-based
# annotation scanner once in a server process.

require 'socket'

class TestScannerServer
  include TmcJavalib
  include Socket::Constants
  
  def initialize
    cmd = "java -cp #{Shellwords.escape(classpath)} #{package}.testscanner.TestScannerServer"
    @pipe = IO.popen(cmd, "r")
    @port_num = @pipe.read.strip.to_i
  end
  
  def get_test_case_methods(course_or_exercise_path)
    socket = connect_socket
    socket.write(course_or_exercise_path + "\n\n")
    socket.flush
    
    received = socket.read
    socket.close
    parse_test_scanner_output(received)
  end
  
  def shut_down!
    socket = connect_socket
    socket.write("SHUTDOWN!")
    socket.close
    @pipe.close
  end
  
private
  def connect_socket
    socket = Socket.new(AF_INET, SOCK_STREAM, 0)
    sockaddr = Socket.pack_sockaddr_in(@port_num, 'localhost')
    socket.connect(sockaddr)
    socket
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    @@javalib_server_instance = TestScannerServer.new
    @@javalib_serverless_instance = TmcJavalib.default_instance
    TmcJavalib.default_instance = @javalib_server_instance
  end
  
  config.before(:each, :use_javalib_server => false) do
    TmcJavalib.default_instance = @@javalib_serverless_instance
  end
  
  config.after(:each, :use_javalib_server => false) do
    @@javalib_server_instance
    TmcJavalib.default_instance = @@javalib_server_instance
  end
  
  config.after(:suite) do
    @@javalib_server_instance.shut_down!
  end
end
