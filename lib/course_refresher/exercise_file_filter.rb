# frozen_string_literal: true

require 'pathname'
require 'fileutils'
require 'tmc_project_file'
require 'course_refresher/java_filter'
require 'course_refresher/xml_filter'
require 'course_refresher/properties_filter'
require 'course_refresher/css_filter'
require 'course_refresher/js_filter'
require 'course_refresher/makefile_c_filter'

class CourseRefresher
  # Filters source files into stubs and solutions.
  class ExerciseFileFilter
    include BadUtf8Helper

    def initialize(project_dir)
      @project_dir = Pathname(project_dir)
      @tmc_project_file = TmcProjectFile.for_project(@project_dir)
    end

    def make_stub(to_dir)
      from_dir = Pathname(@project_dir).expand_path
      to_dir = Pathname(to_dir).expand_path

      TmcLangs.get.make_stubs(from_dir, to_dir)
      clean_empty_dirs_in_project(to_dir)
    end

    def make_solution(to_dir)
      from_dir = Pathname(@project_dir).expand_path
      to_dir = Pathname(to_dir).expand_path

      TmcLangs.get.make_solutions(from_dir, to_dir)
      clean_empty_dirs_in_project(to_dir)
    end

    private
      def clean_empty_dirs_in_project(project_dir)
        clean_empty_dirs_under(project_dir + 'src') if (project_dir + 'src').directory?
        clean_empty_dirs_under(project_dir + 'test') if (project_dir + 'test').directory?
      end

      def clean_empty_dirs_under(dir)
        dir.children.each { |c| clean_empty_dirs(c) if c.directory? }
      end

      def clean_empty_dirs(dir)
        if dir.directory?
          clean_empty_dirs_under(dir)
          dir.rmdir if dir.children.empty?
        end
      end
  end
end
