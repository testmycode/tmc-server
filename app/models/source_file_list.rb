require 'system_commands'
require 'pathname'
require 'find'
require 'tmpdir'
require 'tmc_dir_utils'

class SourceFileList
  include Enumerable

  MAX_SIZE = 2.megabytes

  class FileRecord
    def initialize(path, contents)
      @path = path
      @contents = contents
    end

    attr_reader :path, :contents
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

      files = []
      total_size = 0
      Pathname(project_dir).find do |file|
        Find.prune if file.directory? && should_skip_dir_in_submission?(file)
        if file.file? && file.basename.to_s.end_with?('.java')
          total_size += file.size
          raise "Submission too big" if total_size > MAX_SIZE

          name = file.to_s
          name = name[(project_dir.to_s.size+1)...name.length]
          files << FileRecord.new(name, file.read)
        end
      end

      files = files.sort_by(&:path)

      self.new(files)
    end
  end

private
  def self.should_skip_dir_in_submission?(file)
    name = file.basename.to_s
    name.start_with?('.') || name == 'test' || name == 'lib'
  end
end