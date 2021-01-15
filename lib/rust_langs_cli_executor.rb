# frozen_string_literal: true

require 'fileutils'

# If you want to change the TMC Langs Rust version, see app/background_tasks/rust_langs_downloader_task.rb

module RustLangsCliExecutor
  def self.prepare_submission(clone_path, output_path, submission_path, extra_params = {}, config = {})
    command = "vendor/tmc-langs-rust/current prepare-submission --clone-path #{clone_path} --output-path #{output_path} --submission-path #{submission_path}"

    command = command + " --top-level-dir-name #{config[:toplevel_dir_name]}" if !!config[:toplevel_dir_name]

    command = command + " --stub-zip-path #{config[:tests_from_stub]}" if !!config[:tests_from_stub]

    command = command + " --output-format #{config[:format]}" if !!config[:format]

    extra_params.each do |k, v|
      command = command + " --tmc-param #{k}=#{v}" unless v.nil?
    end

    command_output = `#{command}`
    Rails.logger.info(command_output)

    result = self.process_command_output(command_output)

    if result['result'] == 'error'
      Rails.logger.error('Preparing submission failed: ' + result.to_s)
    end

    result
  end

  def self.refresh(course, course_refresh_task_id, no_background_operations, no_directory_changes)
    command = 'vendor/tmc-langs-rust/current refresh-course'\
    " --cache-path #{course.cache_path}"\
    " --cache-root #{Course.cache_root}"\
    " --clone-path #{course.clone_path}"\
    " --course-name #{course.name}"\
    " --git-branch #{course.git_branch}"\
    " --rails-root #{Rails.root}"\
    " --solution-path #{course.solution_path}"\
    " --solution-zip-path #{course.solution_zip_path}"\
    " --source-backend #{course.source_backend}"\
    " --source-url #{course.source_url}"\
    " --stub-path #{course.stub_path}"\
    " --stub-zip-path #{course.stub_zip_path}"

    command = command + '--no-background-operations' if no_background_operations
    command = command + '--no-directory-changes' if no_directory_changes
    # ENV['RUST_BACKTRACE'] = 'full'

    @course_refresh = CourseRefresh.find(course_refresh_task_id)
    @course_refresh.status = :in_progress
    @course_refresh.save!
    begin
      Open3.popen2(command) do |stdin, stdout, status_thread|
        stdout.each_line do |line|
          Rails.logger.info(line)
          data = parse_as_JSON(line)
          return unless data

          parsed_data = process_command_output_realtime(data)
          ActionCable.server.broadcast('CourseRefreshChannel', parsed_data)
          if data['output-kind'] == 'status-update'
            @course_refresh.percent_done = parsed_data[:percent_done]
            @course_refresh.create_phase(parsed_data[:message], parsed_data[:time])
          elsif data['output-kind'] == 'output-data'
            @course_refresh.percent_done = 1
            @course_refresh.status = :complete
          end
          @course_refresh.save!
          # Rails.logger.info(CourseRefresh.find(course_refresh_task_id))
        end
      end
    rescue StandardError => e
      Rails.logger.error("Error while executing tmc-langs: \n#{e}")
      @course_refresh.status = :crashed
      @course_refresh.percent_done = 0
      @course_refresh.create_phase(e, 0)
      @course_refresh.save!
    end
  end

  private
    def self.process_command_output(command_output)
      output_lines = command_output.split("\n")
      valid_lines = output_lines.map do |line|
        JSON.parse line
      rescue
        nil
      end.select { |line| !!line }

      last_line = valid_lines.last

      if last_line['status'] == 'crashed'
        Rails.logger.info('TMC-langs-rust crashed')
        Rails.logger.info(last_line)
        raise 'TMC-langs-rust crashed: ' + last_line
      end

      last_line
    end

    def self.parse_as_JSON(output)
      JSON.parse output
    rescue StandardError => e
      Rails.logger.info("Could not parse output line. #{e}")
    end

    def self.process_command_output_realtime(command_output)
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
          raise "Refresh failed: \n#{data['trace'].join("\n")}"
        elsif command_output['executed-command']
          data
        end
      end
    end
end
