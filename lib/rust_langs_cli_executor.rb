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

  def self.refresh(course, course_template_refresh_task_id)
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

    # command = 'vendor/tmc-langs-rust/current refresh-course'\
    # " --cache-path #{course.cache_path}"\ # db/files/courses/kurssi-nimi-# <-inkrementoidaan +1
    # " --cache-root #{Course.cache_root}"\ # db/files/courses
    # #" --clone-path #{course.clone_path}"\ cache_path/clone
    # " --course-name #{course.name}"\
    # " --git-branch #{course.git_branch}"\
    # #" --rails-root #{Rails.root}"\ # /tmc-server/
    # #" --chmod-bits #{SiteSetting.value(:git_repos_chmod)}"\ # git_repos_chmod: a+rX
    # #" --chgrp-uid #{SiteSettings.value(:git_repos_chgrp)}"\
    # #" --solution-path #{course.solution_path}"\ cache_path/solution
    # #" --solution-zip-path #{course.solution_zip_path}"\ cache_path/solution_zip
    # #" --source-backend #{course.source_backend}"\ default GIT?
    # " --source-url #{course.source_url}"\ # GIT source url
    # #" --stub-path #{course.stub_path}"\ cache_path/stub
    # #" --stub-zip-path #{course.stub_zip_path}" cache_path/stub_zip

    # command = command + '--no-background-operations' if options[:no_background_operations]
    # command = command + '--no-directory-changes' if options[:no_directory_changes]
    # ENV['RUST_BACKTRACE'] = 'full'

    @course_refresh = CourseTemplateRefresh.find(course_template_refresh_task_id)
    @course_refresh.status = :in_progress

    # begin
    Open3.popen2(command) do |stdin, stdout, status_thread|
      stdout.each_line do |line|
        Rails.logger.info("Rust Refresh output \n#{line}")
        data = parse_as_JSON(line)
        return unless data

        @parsed_data = process_refresh_command_output(data)
        if data['output-kind'] == 'status-update'
          ActionCable.server.broadcast("CourseTemplateRefreshChannel-course-id-#{course.course_template_id}", @parsed_data)
          @course_refresh.percent_done = @parsed_data[:percent_done]
          @course_refresh.create_phase(@parsed_data[:message], @parsed_data[:time])
        end
      end
    end
    @course_refresh.percent_done = 0.95
    @course_refresh.save!
    @parsed_data
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

    def self.process_refresh_command_output(command_output)
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
        elsif command_output['result'] == 'executed-command'
          data
        end
      end
    end
end
