# frozen_string_literal: true

require 'fileutils'

# If you want to change the TMC Langs Rust version, see app/background_tasks/rust_langs_downloader_task.rb

module RustLangsCliExecutor
  def self.prepare_submission(clone_path, output_path, submission_path)
    command = "vendor/tmc-langs-rust/current prepare-submission --clone-path #{clone_path} --output-path #{output_path} --submission-path #{submission_path}"
    command_output = `#{command}`
    Rails.logger.info command_output

    FileUtils.cp(submission_path, 'rust-testing/submission.zip')

    result = self.process_command_output(command_output)

    if result['result'] == 'error'
      Rails.logger.info 'Preparing submission failed: ' + result.to_s
    end

    result
  end

  private

    def self.process_command_output(command_output)
      output_lines = command_output.split("\n")
      valid_lines = output_lines.map do |line|
        begin
          JSON.parse line
        rescue => exception
          nil
        end
      end.select { |line| !!line }

      last_line = valid_lines.last

      if last_line['status'] == 'crashed'
        Rails.logger.info 'TMC-langs-rust crashed'
        Rails.logger.info last_line
        raise 'TMC-langs-rust crashed: ' + last_line
      end

      last_line
    end
end
