require 'system_commands'
require 'pathname'
require 'find'
require 'tmpdir'
require 'tmc_dir_utils'

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
      File.open(zip_path, 'wb') {|f| f.write(submission.return_file) }
      SystemCommands.sh!('unzip', '-qq', zip_path, '-d', tmpdir)
      
      project_dir = TmcDirUtils.find_dir_containing(tmpdir, 'src')
      return self.new([]) if project_dir == nil
    
      files = if project_dir == tmpdir
        find_all_files_under(project_dir)
      else
        find_source_files_under(project_dir)
      end
      make_path_names_relative(project_dir, files)

      files = sort_source_files(files)
      self.new(files)
    end
  end

  def self.for_solution(solution)
    files = find_source_files_under(solution.path)
    files.each do |file|
      html_file = Pathname("#{file.path}.html")
      if html_file.exist?
        file.html_prelude = html_file.read
      end
    end

    make_path_names_relative(solution.path, files)

    files = sort_source_files(files)

    self.new(files)
  end

private
  def self.find_source_files_under(root_dir)
    files = []
    total_size = 0
    Pathname(root_dir).realpath.find do |file|
      Find.prune if file.directory? && should_skip_dir?(file)

      if source_file?(file) && file.size <= MAX_INDIVIDUAL_FILE_SIZE
        total_size += file.size
        raise "Files are too large" if total_size > MAX_SIZE

        files << FileRecord.new(file.to_s, file.read)
      end
    end

    files.sort_by(&:path)
  end

  def self.find_all_files_under(root_dir)
    files = []
    total_size = 0
    Pathname(root_dir).realpath.find do |file|
      if file.size <= MAX_INDIVIDUAL_FILE_SIZE
        total_size += file.size
        raise "Files are too large" if total_size > MAX_SIZE
        name = file.to_s
        next if file.directory? or name.end_with?('.zip') or name.end_with?('.tar') or name.include? "nbproject"
        files << FileRecord.new(file.to_s, file.read)
      end
    end

    files.sort_by(&:path)
  end

  def self.source_file?(file)
    return false unless file.file?
    dir = file.parent.to_s
    name = file.basename.to_s
    name.end_with?('.java') ||
      name.end_with?('.jsp') ||
      (name.end_with?('.xml') && name != 'build.xml') ||
      name.end_with?('.properties') ||
      name.end_with?('.txt') ||
      name.end_with?('.html') ||
      name.end_with?('.css') ||
      name.end_with?('.js') ||
      name.end_with?('.c') ||
      name.end_with?('.h') ||
      name.end_with?('.rb') ||
      dir.include?('/WEB-INF')
  end

  def self.should_skip_dir?(file)
    name = file.basename.to_s
    name.start_with?('.') || name == 'test' || name == 'lib' || name == 'nbproject'
  end

  def self.make_path_names_relative(root_dir, files)
    root_dir = root_dir.to_s
    for file in files
      file.path = file.path[(root_dir.size+1)...file.path.length] if file.path.start_with?(root_dir)
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
