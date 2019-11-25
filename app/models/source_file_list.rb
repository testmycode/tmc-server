# frozen_string_literal: true

require 'find'
require 'pathname'
require 'safe_unzipper'
require 'system_commands'
require 'tmc_dir_utils'
require 'tmpdir'

# Represents a list of source code files for the web UI to display.
class SourceFileList
  include Enumerable

  MAX_SIZE = 3.megabytes
  MAX_INDIVIDUAL_FILE_SIZE = 300.kilobytes

  class FileRecord
    def initialize(path, contents)
      @path = path
      @contents = contents
      @html_prelude = nil
    end

    attr_accessor :path, :contents, :html_prelude
  end

  def initialize(files)
    @files = files
  end

  def each(&block)
    @files.each(&block)
  end

  def self.for_submission(submission)
    Dir.mktmpdir do |tmpdir|
      zip_path = "#{tmpdir}/submission.zip"
      File.open(zip_path, 'wb') { |f| f.write(submission.return_file) }
      SafeUnzipper.new.unzip(zip_path, tmpdir)

      project_dir = TmcDirUtils.find_dir_containing(tmpdir, 'src')
      return new([]) if project_dir.nil?

      files = if project_dir == tmpdir
        find_all_files_under(project_dir)
      else
        find_source_files_under(project_dir)
      end

      return new([]) unless submission.exercise

      project_file = TmcProjectFile.for_project(submission.exercise.clone_path)

      project_file&.extra_student_files&.each do |f|
        file = Pathname.new(File.join(project_dir, f))
        if source_file?(file) && file.size <= MAX_INDIVIDUAL_FILE_SIZE
          files << FileRecord.new(file.to_s, file.read)
        end
      end

      make_path_names_relative(project_dir, files)
      files = sort_source_files(files)
      new(files)
    end
  end

  def self.for_solution(solution)
    project_file = TmcProjectFile.for_project(solution.exercise.clone_path)
    files = if project_file&.show_all_files_in_solution
      find_all_files_under(solution.path)
    else
      find_source_files_under(solution.path)
    end
    files.each do |file|
      html_file = Pathname("#{file.path}.html")
      file.html_prelude = html_file.read if html_file.exist?
    end

    make_path_names_relative(solution.path, files)

    files = sort_source_files(files)

    new(files)
  end

  private

    def self.find_source_files_under(root_dir)
      files = []
      total_size = 0
      Pathname(root_dir).realpath.find do |file|
        Find.prune if file.directory? && should_skip_dir?(file)

        next unless source_file?(file) && file.size <= MAX_INDIVIDUAL_FILE_SIZE
        total_size += file.size
        raise 'Files are too large' if total_size > MAX_SIZE

        files << FileRecord.new(file.to_s, file.read)
      end

      files.sort_by(&:path)
    end

    def self.find_all_files_under(root_dir)
      files = []
      total_size = 0
      Pathname(root_dir).realpath.find do |file|
        next unless file.size <= MAX_INDIVIDUAL_FILE_SIZE
        total_size += file.size
        raise 'Files are too large' if total_size > MAX_SIZE
        name = file.to_s
        next if file.directory? || name.end_with?('.zip') || name.end_with?('.tar') || name.include?('nbproject')
        files << FileRecord.new(file.to_s, file.read)
      end

      files.sort_by(&:path)
    end

    def self.source_file?(file)
      return false unless file.file?
      dir = file.parent.to_s
      name = file.basename.to_s
      name.end_with?('.java', '.jsp') ||
        (name.end_with?('.xml') && name != 'build.xml' && name != 'pom.xml' && !name.end_with?('checkstyle.xml')) ||
        name.end_with?('.properties') ||
        name.end_with?('.txt') ||
        name.end_with?('.html') ||
        name.end_with?('.css') ||
        name.end_with?('.less') ||
        name.end_with?('.sass') ||
        name.end_with?('.js') ||
        name.end_with?('.c') ||
        name.end_with?('.cpp') ||
        name.end_with?('.qml') ||
        name.end_with?('.hpp') ||
        name.end_with?('.h') ||
        name.end_with?('.rb') ||
        (dir.include?('/R') && name.end_with?('.R')) ||
        (dir.include?('/src') && name.end_with?('.py')) ||
        dir.include?('/WEB-INF')
    end

    def self.should_skip_dir?(file)
      name = file.basename.to_s
      name.start_with?('.') || name == 'test' || name == 'lib' || name == 'nbproject' || name == 'bower_components' || name == 'test_runner'
    end

    def self.make_path_names_relative(root_dir, files)
      root_dir = root_dir.to_s
      for file in files
        file.path = file.path[(root_dir.size + 1)...file.path.length] if file.path.start_with?(root_dir)
      end
    end

    def self.sort_source_files(files)
      files.sort_by do |f|
        priority = begin
          if f.path.include?('WEB-INF/') then 1
          elsif f.path.start_with?('src/main/resources') then 2
          elsif f.path == 'pom.xml' then 3
          else 0
          end
        end
        [priority, f.path]
      end
    end
end
