# typed: strict
# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'shellwords'

# If you want to change the TMC Langs Rust version, see app/background_tasks/rust_langs_downloader_task.rb

module RustLangsCliExecutor
  extend T::Sig

  # Returns the last JSON line tmc-langs printed.
  sig do
    params(
      clone_path: String,
      output_path: String,
      submission_path: String,
      extra_params: T::Hash[T.untyped, T.untyped],
      config: T::Hash[Symbol, T.untyped]
    ).returns(T.untyped)
  end
  def self.prepare_submission(clone_path, output_path, submission_path, extra_params = {}, config = {})
    command = ["#{self.langs_executable_path}/current", 'prepare-submission',
               '--clone-path', clone_path, '--output-path', output_path, '--submission-path', submission_path]
    command << '--no-archive-prefix' if config[:no_archive_prefix]
    command.push('--stub-archive-path', config[:tests_from_stub].to_s) if config[:tests_from_stub]
    command.push('--output-format', config[:format].to_s) if config[:format]
    extra_params.each do |k, v|
      command.push('--tmc-param', "#{k}=#{v}") unless v.nil?
    end

    command_output = self.capture_stdout(command)
    Rails.logger.info(command_output)

    result = self.process_prepare_submission_command_output(command_output)

    if result['result'] == 'error'
      Rails.logger.error('Preparing submission failed: ' + result.to_s)
    end

    result
  end

  # Returns the data of tmc-langs' last output line, or nil if it printed a non-JSON line.
  sig { params(course_template_refresh_task: CourseTemplateRefresh).returns(T.untyped) }
  def self.refresh(course_template_refresh_task)
    course_template = T.must(course_template_refresh_task.course_template)
    command = ["#{self.langs_executable_path}/current", 'refresh-course',
               '--cache-path', course_template.cache_path,
               '--cache-root', Course.cache_root,
               '--course-name', course_template.name.to_s,
               '--git-branch', course_template.git_branch,
               '--source-url', course_template.source_url.to_s]

    Rails.logger.info(command.shelljoin)
    parsed_data = T.let(nil, T.untyped)

    T.unsafe(Open3).popen2(*command) do |_stdin, stdout, status_thread|
      Timeout.timeout(600, Timeout::Error, 'Refresh process took more than 10 minutes...') do
        stdout.each_line do |line|
          Rails.logger.info("Rust Refresh output \n#{line}")
          data = parse_as_JSON(line)
          return nil unless data

          parsed_data = self.process_refresh_command_output(data)
          if data['output-kind'] == 'status-update'
            ActionCable.server.broadcast("CourseTemplateRefreshChannel-#{course_template.id}", parsed_data) unless parsed_data[:percent_done] == 1.0 # rubocop:disable Lint/FloatComparison -- tmc-langs reports exactly 1.0 when done
            course_template_refresh_task.percent_done = parsed_data[:percent_done]
            course_template_refresh_task.create_phase(parsed_data[:message], parsed_data[:time])
          end
        end
      end
    rescue Timeout::Error => e
      Rails.logger.info("Rust Refresh took too long, killing process. #{e}")
      self.kill_process(status_thread.pid)
      raise e
    end
    course_template_refresh_task.percent_done = BigDecimal('0.95')
    course_template_refresh_task.save!
    parsed_data
  end

  # Kills the child if the caller's Timeout interrupts the read; Open3 would otherwise wait for it to exit.
  sig { params(command: T::Array[String]).returns(String) }
  private_class_method def self.capture_stdout(command)
    T.unsafe(Open3).popen2(*command) do |_stdin, stdout, wait_thread|
      finished = false
      begin
        output = stdout.read.to_s
        finished = true
        output
      ensure
        self.kill_process(wait_thread.pid) unless finished
      end
    end
  end

  sig { params(pid: Integer).void }
  private_class_method def self.kill_process(pid)
    Process.kill('KILL', pid)
  rescue Errno::ESRCH
    nil
  end

  sig { params(output: String).returns(T.untyped) }
  private_class_method def self.parse_as_JSON(output)
    JSON.parse output
  rescue StandardError => e
    Rails.logger.info("Could not parse output line. #{e}")
  end

  sig { returns(String) }
  private_class_method def self.langs_executable_path
    Rails.root.join('vendor/tmc-langs-rust').relative_path_from(Pathname.new(Dir.pwd)).to_s
  end

  sig { params(command_output: String).returns(T.untyped) }
  private_class_method def self.process_prepare_submission_command_output(command_output)
    output_lines = command_output.split("\n")
    valid_lines = output_lines.map do |line|
      JSON.parse line
    rescue
      nil
    end.select { |line| !!line }

    last_line = valid_lines.last
    raise 'TMC-langs-rust printed no JSON output' if last_line.nil?

    if last_line['status'] == 'crashed'
      Rails.logger.info('TMC-langs-rust crashed')
      Rails.logger.info(last_line)
      raise "TMC-langs-rust crashed: #{last_line.to_json}"
    end

    last_line
  end

  sig { params(command_output: T.untyped).returns(T.untyped) }
  private_class_method def self.process_refresh_command_output(command_output)
    data = command_output['data']
    if command_output['status'] == 'crashed'
      raise "TMC-langs-rust crashed: \n#{data}"
    elsif command_output['output-kind'] == 'status-update'
      {
        message: command_output['message'],
        percent_done: command_output['percent-done'],
        time: command_output['time'],
      }
    elsif command_output['status'] == 'finished'
      if command_output['result'] == 'error'
        raise data['output-data']['trace'].join("\n")
      elsif command_output['result'] == 'executed-command'
        data
      end
    end
  end
end
