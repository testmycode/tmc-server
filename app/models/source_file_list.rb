# typed: strict
# frozen_string_literal: true

require 'find'
require 'pathname'
require 'safe_unzipper'
require 'system_commands'
require 'tmc_dir_utils'
require 'tmpdir'

# Represents a list of source code files for the web UI to display.
class SourceFileList
  extend T::Sig
  extend T::Generic
  include Enumerable

  MAX_SIZE = T.let(3.megabytes, Integer)
  MAX_INDIVIDUAL_FILE_SIZE = T.let(300.kilobytes, Integer)

  class FileRecord
    extend T::Sig
    sig { params(path: String, contents: String).void }
    def initialize(path, contents)
      @path = path
      @contents = contents
      @html_prelude = T.let(nil, T.nilable(String))
    end

    sig { returns(String) }
    attr_accessor :path, :contents
    sig { returns(T.nilable(String)) }
    attr_accessor :html_prelude
  end

  sig { params(files: T::Array[FileRecord]).void }
  def initialize(files)
    @files = files
  end

  Elem = type_member { { fixed: FileRecord } }

  sig { override.params(block: T.nilable(T.proc.params(file: FileRecord).void)).returns(T.any(T::Array[FileRecord], T::Enumerator[FileRecord])) }
  def each(&block)
    return @files.each unless block
    @files.each(&block)
  end

  sig { params(submission: Submission).returns(T.attached_class) }
  def self.for_submission(submission)
    Dir.mktmpdir do |tmpdir|
      zip_path = "#{tmpdir}/submission.zip"
      File.open(zip_path, 'wb') { |f| f.write(submission.return_file) }
      SafeUnzipper.new.unzip(zip_path, tmpdir)

      project_dir = TmcDirUtils.find_dir_containing(tmpdir, 'src')
      return new([]) if project_dir.nil?

      files = find_source_files_under(project_dir)

      exercise = submission.exercise
      return new([]) unless exercise

      project_file = TmcProjectFile.for_project(exercise.clone_path)

      project_file.extra_student_files.each do |f|
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

  sig { params(solution: Solution).returns(T.attached_class) }
  def self.for_solution(solution)
    project_file = TmcProjectFile.for_project(solution.exercise.clone_path)
    files = if project_file.show_all_files_in_solution
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
    sig { params(root_dir: T.any(String, Pathname)).returns(T::Array[FileRecord]) }
    def self.find_source_files_under(root_dir)
      files = T.let([], T::Array[FileRecord])
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

    sig { params(root_dir: T.any(String, Pathname)).returns(T::Array[FileRecord]) }
    def self.find_all_files_under(root_dir)
      files = T.let([], T::Array[FileRecord])
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

    sig { params(file: Pathname).returns(T::Boolean) }
    def self.source_file?(file)
      return false unless file.file?
      dir = file.parent.to_s
      name = file.basename.to_s.downcase
      name.end_with?('.java', '.jsp') ||
        (name.end_with?('.xml') && name != 'build.xml' && name != 'pom.xml' && name != 'nbactions.xml' && !name.end_with?('checkstyle.xml')) ||
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
        (dir.include?('/R') && name.end_with?('.r')) ||
        (dir.include?('/src') && name.end_with?('.py')) ||
        dir.include?('/WEB-INF') ||
        name.end_with?('.cs')
    end

    sig { params(file: Pathname).returns(T::Boolean) }
    def self.should_skip_dir?(file)
      name = file.basename.to_s
      name.start_with?('.') || name == 'test' || name == 'lib' || name == 'nbproject' || name == 'bower_components' || name == 'test_runner'
    end

    sig { params(root_dir: T.any(String, Pathname), files: T::Array[FileRecord]).void }
    def self.make_path_names_relative(root_dir, files)
      root_dir = root_dir.to_s
      for file in files
        file.path = T.must(file.path[(root_dir.size + 1)...file.path.length]) if file.path.start_with?(root_dir)
      end
    end

    sig { params(files: T::Array[FileRecord]).returns(T::Array[FileRecord]) }
    def self.sort_source_files(files)
      files.sort_by do |f|
        priority = if f.path.include?('WEB-INF/') then 1
        elsif f.path.start_with?('src/main/resources') then 2
        elsif f.path == 'pom.xml' then 3
        else 0
        end

        [priority, f.path]
      end
    end
end
