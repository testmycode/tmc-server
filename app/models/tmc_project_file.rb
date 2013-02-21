require 'pathname'

# Represents a `.tmcproject.yml` file.
class TmcProjectFile
  def initialize(data)
    @extra_student_files = []

    return if !data.is_a?(Hash)
    @extra_student_files = data['extra_student_files'] if data['extra_student_files'].is_a?(Array)
    filter_extra_student_files!
  end

  attr_reader :extra_student_files

  def self.for_project(project_dir)
    begin
      file = Pathname(project_dir) + '.tmcproject.yml'
      TmcProjectFile.new(YAML.load_file(file))
    rescue
      self.empty
    end
  end

private
  def self.empty
    TmcProjectFile.new({})
  end

  def filter_extra_student_files!
    @extra_student_files.reject! {|path| path.include?('..') }
  end
end