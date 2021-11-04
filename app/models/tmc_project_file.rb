# frozen_string_literal: true

require 'pathname'

# Represents a `.tmcproject.yml` file.
class TmcProjectFile
  def initialize(data)
    @extra_student_files = []

    return unless data.is_a?(Hash)
    @extra_student_files = data['extra_student_files'] if data['extra_student_files'].is_a?(Array)
    @show_all_files_in_solution = data['show_all_files_in_solution']
    filter_extra_student_files!
    @data = data
  end

  attr_reader :extra_student_files
  attr_reader :show_all_files_in_solution

  def self.for_project(project_dir)
    file = Pathname(project_dir) + '.tmcproject.yml'
    TmcProjectFile.new(YAML.load_file(file))
  rescue StandardError
    empty
  end

  private
    def self.empty
      TmcProjectFile.new({})
    end

    def filter_extra_student_files!
      @extra_student_files.reject! { |path| path.include?('..') }
    end
end
