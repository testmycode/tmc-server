# typed: strict
# frozen_string_literal: true

require 'find'
require 'system_commands'

# Extracts untrusted zips, leaving only regular files and directories behind.
class SafeUnzipper
  extend T::Sig

  # Far above any real exercise project; only archives built to exhaust the server reach these.
  MAX_ENTRIES = 10_000
  MAX_UNCOMPRESSED_BYTES = T.let(100 * 1024 * 1024, Integer)
  # Per command; the three commands of an unzip must together fit in Rack::Timeout's 120 s.
  TIMEOUT_SECONDS = 30

  # Raised for archives over the entry, size or time limits.
  class ArchiveTooLargeError < StandardError; end

  sig { params(zip_path: T.any(String, Pathname), dest_dir: T.any(String, Pathname)).void }
  def unzip(zip_path, dest_dir)
    zip_path = zip_path.to_s
    dest_dir = File.absolute_path(dest_dir)
    check_limits(zip_path)
    # Ideally we'd protect against `unzip` exploits too by running in a sandbox
    run_with_timeout('unzip', '-qqu', zip_path, '-d', dest_dir)
    clean_up(dest_dir)
  end

  private
    sig { params(zip_path: String).void }
    def check_limits(zip_path)
      summary = run_with_timeout('zipinfo', '-t', zip_path)
      entry_count = summary[/(\d+) files?,/, 1]
      raise "Unexpected zipinfo output: #{summary}" if entry_count.nil?
      raise ArchiveTooLargeError, "the archive has more than #{MAX_ENTRIES} files." if entry_count.to_i > MAX_ENTRIES
      raise ArchiveTooLargeError, "the archive extracts to more than #{MAX_UNCOMPRESSED_BYTES / 1024 / 1024} MB." if uncompressed_bytes_over_limit?(zip_path)
    end

    sig { params(command: String).returns(String) }
    def run_with_timeout(*command)
      T.unsafe(SystemCommands).sh!(*command, timeout: TIMEOUT_SECONDS)[:output]
    rescue SystemCommands::TimeoutError
      raise ArchiveTooLargeError, 'the archive took too long to extract.'
    end

    # Decompresses to a pipe instead of trusting the sizes in the archive's headers, which can lie.
    sig { params(zip_path: String).returns(T::Boolean) }
    def uncompressed_bytes_over_limit?(zip_path)
      total_bytes = 0
      IO.popen(['timeout', TIMEOUT_SECONDS.to_s, 'unzip', '-p', '-qq', zip_path], 'rb', in: File::NULL, err: File::NULL) do |io|
        while (chunk = io.read(64 * 1024))
          total_bytes += chunk.bytesize
          return true if total_bytes > MAX_UNCOMPRESSED_BYTES
        end
      end
      raise ArchiveTooLargeError, 'the archive took too long to extract.' if $?.exitstatus == 124
      false
    end

    # Even links that look internal can escape through chained links, and
    # nothing reading the extracted files needs them.
    sig { params(dest_dir: String).void }
    def clean_up(dest_dir)
      Find.find(dest_dir) do |path|
        stat = File.lstat(path)
        next if stat.directory? || stat.file?

        ::Rails.logger.warn("Removing #{stat.ftype} from unzipped archive: #{path}")
        File.unlink(path)
      end
    end
end
