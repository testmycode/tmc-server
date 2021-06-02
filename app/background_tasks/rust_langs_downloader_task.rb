# frozen_string_literal: true

require 'rust_langs_cli_executor'

class RustLangsDownloaderTask
  @@rust_langs_version = '0.17.2.3'

  def initialize
  end

  def run
    Rails.logger.info('Creating directory vendor/tmc-langs-rust') unless File.directory?('vendor/tmc-langs-rust')
    Dir.mkdir('vendor/tmc-langs-rust') unless File.directory?('vendor/tmc-langs-rust')

    executable = "vendor/tmc-langs-rust/tmc-langs-cli-x86_64-unknown-linux-gnu-#{@@rust_langs_version}"

    unless File.exist?(executable)
      previous = nil
      previous = File.readlink('vendor/tmc-langs-rust/current') if File.exist? 'vendor/tmc-langs-rust/current'
      previous = nil if previous == executable

      Rails.logger.info("Downloading tmc-langs-cli-x86_64-unknown-linux-gnu-#{@@rust_langs_version}")
      `wget https://download.mooc.fi/tmc-langs-rust/tmc-langs-cli-x86_64-unknown-linux-gnu-#{@@rust_langs_version} -O #{executable}`
      `chmod +x #{executable}`

      command_output = `#{executable} --help`
      unless command_output.include?('tmc-langs')
        Rails.logger.error("Downloaded file did not work, removing #{executable}")
        File.delete(executable)
        return
      end

      Dir.chdir('vendor/tmc-langs-rust') do
        File.symlink("tmc-langs-cli-x86_64-unknown-linux-gnu-#{@@rust_langs_version}", 'new-current')
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

  def wait_delay
    1
  end
end
