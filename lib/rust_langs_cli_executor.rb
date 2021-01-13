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
    command = "vendor/tmc-langs-rust/current refresh-course"\
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

    File.open('course_refresh.txt', 'w') do |file|
      file.puts(`#{command}`)
    end
    command_output = File.open('course_refresh.txt').read
    
    @@refresh_logger ||= Logger.new("#{Rails.root}/log/course_refresh.log")

    @@refresh_logger.info(`#{command}`)

    Rails.logger.info(command_output)

    result = self.process_command_output(command_output)

    if result['result'] == 'error'
      Rails.logger.error("Refreshing course #{course.name} failed: " + result.to_s)
    end

    File.delete('course_refresh.txt')

    result
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

    # from https://stackoverflow.com/questions/1293695/watch-read-a-growing-log-file
    def self.watch_for(file, pattern)
      f = File.open(file,"r")
      f.seek(0,IO::SEEK_END)
      while true do
        select([f])
        line = f.gets
        puts "Found it! #{line}" if line=~pattern
      end
    end
    
    
end
