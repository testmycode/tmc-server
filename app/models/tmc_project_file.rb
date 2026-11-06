# typed: strict
# frozen_string_literal: true

require 'pathname'

# Represents a `.tmcproject.yml` file.
class TmcProjectFile
  extend T::Sig
  # data is the parsed YAML, so it may be anything.
  sig { params(data: T.untyped).void }
  def initialize(data)
    @extra_student_files = T.let([], T::Array[String])
    @show_all_files_in_solution = T.let(nil, T.untyped)
    @data = T.let(nil, T.untyped)

    return unless data.is_a?(Hash)
    @extra_student_files = data['extra_student_files'] if data['extra_student_files'].is_a?(Array)
    @show_all_files_in_solution = data['show_all_files_in_solution']
    filter_extra_student_files!
    @data = data
  end

  sig { returns(T::Array[String]) }
  attr_reader :extra_student_files
  sig { returns(T.untyped) }
  attr_reader :show_all_files_in_solution

  sig { params(project_dir: T.any(String, Pathname)).returns(TmcProjectFile) }
  def self.for_project(project_dir)
    file = Pathname(project_dir) + '.tmcproject.yml'
    TmcProjectFile.new(YAML.load_file(file))
  rescue StandardError
    empty
  end

  private
    sig { returns(TmcProjectFile) }
    private_class_method def self.empty
      TmcProjectFile.new({})
    end

    sig { void }
    def filter_extra_student_files!
      @extra_student_files.reject! { |path| path.include?('..') }
    end
end
