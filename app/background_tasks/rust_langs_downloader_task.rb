# typed: strict
# frozen_string_literal: true

require 'digest'
require 'rust_langs_cli_executor'

class RustLangsDownloaderTask
  extend T::Sig

  # Raised when wget fails to download the tmc-langs binary.
  class DownloadFailed < StandardError; end

  # Raised when a downloaded tmc-langs binary does not match RUST_LANGS_SHA256.
  class ChecksumMismatch < StandardError; end

  # Raised when a downloaded tmc-langs binary with the right checksum cannot run on this host.
  class BinaryDoesNotRun < StandardError; end

  # Bump together: the hash is that of the x86_64 Linux binary of this version, as published
  # next to it at download.mooc.fi in tmc-langs-cli-x86_64-unknown-linux-gnu-<version>.sha256.
  RUST_LANGS_VERSION = '0.39.8'
  RUST_LANGS_SHA256 = '0c39368c5c70fb89ae30fe38619c1870522ee512ee67f6f59ab8e5a2dfd45f73'

  FIRST_RETRY_DELAY_SECONDS = 60
  MAX_RETRY_DELAY_SECONDS = 3600

  sig { void }
  def initialize
    @retry_delay_seconds = T.let(nil, T.nilable(Integer))
  end

  sig { void }
  def run
    Rails.logger.info('Creating directory vendor/tmc-langs-rust') unless File.directory?('vendor/tmc-langs-rust')
    Dir.mkdir('vendor/tmc-langs-rust') unless File.directory?('vendor/tmc-langs-rust')

    executable = "vendor/tmc-langs-rust/tmc-langs-cli-x86_64-unknown-linux-gnu-#{RUST_LANGS_VERSION}"

    unless File.exist?(executable)
      previous = nil
      previous = File.readlink('vendor/tmc-langs-rust/current') if File.exist? 'vendor/tmc-langs-rust/current'
      previous = nil if previous == executable

      Rails.logger.info("Downloading tmc-langs-cli-x86_64-unknown-linux-gnu-#{RUST_LANGS_VERSION}")
      download = "#{executable}.download"
      begin
        download!(download)
        verify_checksum!(download)
        File.chmod(0o755, download)
        verify_runs!(download)
      rescue DownloadFailed, ChecksumMismatch, BinaryDoesNotRun => e
        FileUtils.rm_f(download)
        Rails.logger.error(e.message)
        @retry_delay_seconds = @retry_delay_seconds ? [@retry_delay_seconds * 2, MAX_RETRY_DELAY_SECONDS].min : FIRST_RETRY_DELAY_SECONDS
        raise
      end
      @retry_delay_seconds = nil
      File.rename(download, executable)

      Dir.chdir('vendor/tmc-langs-rust') do
        File.symlink("tmc-langs-cli-x86_64-unknown-linux-gnu-#{RUST_LANGS_VERSION}", 'new-current')
        File.rename('new-current', 'current')
      end
      Rails.logger.info('TMC langs rust downloaded')

      sleep(10)

      if previous
        previous_path = "vendor/tmc-langs-rust/#{previous}"
        Rails.logger.info("Removing #{previous_path}")
        File.delete(previous_path)
      end
    end
  end

  # Seconds until the daemon runs the task again: 1 normally, doubling from FIRST_RETRY_DELAY_SECONDS
  # up to MAX_RETRY_DELAY_SECONDS after consecutive failed downloads.
  sig { returns(Integer) }
  def wait_delay
    @retry_delay_seconds || 1
  end

  private
    # Downloads the pinned version to `path`, raising DownloadFailed if wget fails.
    sig { params(path: String).void }
    def download!(path)
      return if system('wget', "https://download.mooc.fi/tmc-langs-rust/tmc-langs-cli-x86_64-unknown-linux-gnu-#{RUST_LANGS_VERSION}", '-O', path)

      raise DownloadFailed, "wget failed to download tmc-langs #{RUST_LANGS_VERSION}: #{Process.last_status.inspect}"
    end

    # Raises BinaryDoesNotRun unless `path` runs and identifies itself as tmc-langs.
    sig { params(path: String).void }
    def verify_runs!(path)
      command_output = begin
        IO.popen([path, '--help'], &:read)
      rescue SystemCallError
        ''
      end
      return if command_output.include?('tmc-langs')

      raise BinaryDoesNotRun, "Downloaded tmc-langs #{RUST_LANGS_VERSION} did not run; removed it"
    end

    # Raises ChecksumMismatch unless `path` holds the pinned binary.
    sig { params(path: String).void }
    def verify_checksum!(path)
      actual = File.file?(path) ? Digest::SHA256.file(path).hexdigest : nil
      return if actual == RUST_LANGS_SHA256

      raise ChecksumMismatch, "tmc-langs #{RUST_LANGS_VERSION} download has SHA-256 #{actual || 'none'}, expected #{RUST_LANGS_SHA256}; removed it"
    end
end
