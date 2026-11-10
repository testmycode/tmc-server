# typed: false
# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'net/http'
require 'open3'
require 'tmpdir'

# Drives the published tmc-langs-cli build that a client ships, against the test server,
# the way that client does. Entries come from spec/client_compat/clients.json.
class TmcLangsClient
  # A tmc-langs command failed, timed out or printed output of an unexpected kind.
  class CommandFailed < StandardError; end

  # A command running in the background, like the blocking `submit` a client waits on.
  class Run
    def initialize(command, env, stdin)
      @command = command
      stdin_pipe, stdout, stderr, @wait_thread = Open3.popen3(env, *command)
      @stdout = Thread.new { stdout.read.tap { stdout.close } }
      @stderr = Thread.new { stderr.read.tap { stderr.close } }
      begin
        stdin_pipe.write(stdin) if stdin
      rescue Errno::EPIPE
        nil # it exited without reading stdin; its output says why
      end
      stdin_pipe.close
    end

    def running?
      @wait_thread.alive?
    end

    # The last output line, parsed; raises unless the command finished successfully.
    def result(timeout: TIMEOUT_SECONDS)
      last = last_line(timeout)
      raise CommandFailed, "#{description} failed\n#{output}" if last['result'] == 'error'
      last
    end

    # The error output data of a command that is expected to fail.
    def error(timeout: TIMEOUT_SECONDS)
      last = last_line(timeout)
      raise CommandFailed, "#{description} did not fail\n#{output}" unless last['result'] == 'error'
      last.dig('data', 'output-data')
    end

    private
      def last_line(timeout)
        unless @wait_thread.join(timeout)
          begin
            Process.kill('KILL', @wait_thread.pid)
          rescue Errno::ESRCH
            nil
          end
          raise CommandFailed, "#{description} timed out after #{timeout} s\n#{output}"
        end
        last = @stdout.value.lines.reverse_each.lazy.filter_map { |line| JSON.parse(line) rescue nil }.first
        raise CommandFailed, "#{description} printed no result\n#{output}" unless last && last['status'] == 'finished'
        last
      end

      def description
        @command.drop(1).join(' ')
      end

      def output
        "stdout:\n#{@stdout.value}\nstderr:\n#{@stderr.value}"
      end
  end

  TIMEOUT_SECONDS = 60
  MANIFEST_PATH = Rails.root.join('spec/client_compat/clients.json')

  # TMC_LANGS_CLIENT=<client_name>@<client_version> limits the suite to one client, as each CI job does.
  def self.manifest
    clients = JSON.parse(File.read(MANIFEST_PATH), symbolize_names: true)
    only = ENV['TMC_LANGS_CLIENT'].presence
    return clients unless only

    clients.select { |client| "#{client[:client_name]}@#{client[:client_version]}" == only }.presence ||
      raise("TMC_LANGS_CLIENT=#{only} matches no client in #{MANIFEST_PATH}")
  end

  # client: one manifest entry. root_url: the server the client talks to.
  def initialize(client, root_url, dir)
    @client_name = client[:client_name]
    @client_version = client[:client_version]
    @credentials_path = File.join(dir, 'config', "tmc-#{@client_name}", 'credentials.json')
    @executable = self.class.fetch_executable(client[:langs_version], client[:sha256])
    @env = {
      'TMC_LANGS_TMC_ROOT_URL' => root_url,
      # Nothing listens here; the commands under test never need courses.mooc.fi.
      'TMC_LANGS_MOOC_ROOT_URL' => 'http://127.0.0.1:9/',
      'TMC_LANGS_CONFIG_DIR' => File.join(dir, 'config'),
      'TMC_LANGS_DEFAULT_PROJECTS_DIR' => File.join(dir, 'projects'),
      'RUST_LOG' => 'info'
    }
  end

  # Runs `tmc <args>` and returns the output data, checking it is of the expected kind (nil for none).
  def tmc(*args, kind:, stdin: nil)
    data = start(*args, stdin: stdin).result['data'] || {}
    output_kind = data['output-data-kind']
    raise CommandFailed, "#{args.first} returned #{output_kind.inspect}, not #{kind.inspect}" unless output_kind == kind
    data['output-data']
  end

  # Starts `tmc <args>` and returns the Run without waiting, for a command expected to fail or to
  # check on while it runs; #tmc is the blocking form.
  def start(*args, stdin: nil)
    Run.new([@executable, 'tmc', '--client-name', @client_name, '--client-version', @client_version, *args.map(&:to_s)], @env, stdin)
  end

  # Where the client keeps its OAuth token.
  attr_reader :credentials_path

  # Downloads the build once into vendor/, next to the one the server packages submissions with.
  def self.fetch_executable(version, sha256)
    @executables ||= {}
    @executables[[version, sha256]] ||= download_executable(version, sha256)
  end

  private_class_method def self.download_executable(version, sha256)
    path = Rails.root.join('vendor/tmc-langs-rust/clients', "tmc-langs-cli-#{version}").to_s
    return path if File.exist?(path) && Digest::SHA256.file(path).hexdigest == sha256

    response = Net::HTTP.get_response(URI(RustLangsDownloaderTask.download_url(version)))
    raise "Downloading tmc-langs-cli #{version} failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    actual = Digest::SHA256.hexdigest(response.body)
    raise "tmc-langs-cli #{version} has checksum #{actual}, expected #{sha256}" unless actual == sha256

    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite("#{path}.part", response.body)
    File.chmod(0o755, "#{path}.part")
    File.rename("#{path}.part", path)
    path
  end
end
