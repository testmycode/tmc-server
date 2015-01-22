require 'pathname'
require 'fileutils'
require 'mimemagic'
require 'tmc_project_file'
require 'course_refresher/java_filter'
require 'course_refresher/xml_filter'
require 'course_refresher/properties_filter'
require 'course_refresher/css_filter'
require 'course_refresher/js_filter'
require 'course_refresher/makefile_c_filter'

class CourseRefresher
  # Filters source files into stubs and solutions.
  #
  # See the user manual for the special comments this processes.
  class ExerciseFileFilter
    include BadUtf8Helper

    def initialize(project_dir)
      @project_dir = Pathname(project_dir)
      @tmc_project_file = TmcProjectFile.for_project(@project_dir)
    end

    def make_stub(to_dir)
      from_dir = Pathname(@project_dir).expand_path
      to_dir = Pathname(to_dir).expand_path

      paths = files_for_stub(from_dir)
      while_copying(from_dir, to_dir, paths) do |rel_path|
        from = from_dir + rel_path
        to = to_dir + rel_path
        contents = filter_file_for_stub(from)
        write_file(to, contents) unless contents.nil?
      end

      clean_empty_dirs_in_project(to_dir)
    end

    def make_solution(to_dir)
      from_dir = Pathname(@project_dir).expand_path
      to_dir = Pathname(to_dir).expand_path

      paths = files_for_solution(from_dir)
      while_copying(from_dir, to_dir, paths) do |rel_path|
        from = from_dir + rel_path
        to = to_dir + rel_path
        contents = filter_file_for_solution(from)
        write_file(to, contents) unless contents.nil?
        maybe_write_html_file(read_file_utf8(from), "#{to}.html") if looks_like_text_file?(from)
      end

      clean_empty_dirs_in_project(to_dir)
    end

  private
    def looks_like_text_file?(path)
      mime = MimeMagic.by_path(path.to_s)
      mime ||= File.open(path) do |f|
        MimeMagic.by_magic(f)
      end
      mime && mime.text?
    end

    def read_file_utf8(path)
      if looks_like_text_file?(path)
        force_utf8_violently(File.read(path))
      else
        File.read(path)
      end
    end

    def write_file(path, contents)
      File.open(path, 'wb') {|f| f.write(contents) }
    end

    def while_copying(from_dir, to_dir, paths, &block)
      for path in paths
        if (from_dir + path).directory?
          FileUtils.mkdir_p(to_dir + path)
        else
          block.call(path)
        end
      end
    end

    # Returns a sorted list of relative pathnames to files that should be in the stub
    def files_for_stub(from_dir)
      filter_relative_pathnames(from_dir) do |path|
        should_include_in_stub(path)
      end
    end

    def files_for_solution(from_dir)
      filter_relative_pathnames(from_dir) do |path|
        should_include_in_solution(path)
      end
    end

    def filter_relative_pathnames(dir, &block)
      result = []
      Dir.chdir(dir) do
        Pathname('.').find do |path|
          if path.directory? || block.call(path)
            result << path unless path.to_s == '.'
          end
        end
      end
      result.sort
    end

    def should_include_in_stub(path)
      fn = path.basename.to_s
      !(fn.include?('hidden') || fn.include?('Hidden') || fn.start_with?('.git') || fn == 'metadata.yml' || fn == '.tmcrc')
    end

    def should_include_in_solution(path)
      fn = path.basename.to_s
      rel_path = path.to_s
      return true if @tmc_project_file.extra_student_files.include?(rel_path)
      return false if rel_path =~ /(?:^|\/)test(?:\/|$)/
      return false if fn.start_with?('.git')
      return false if ['.tmcproject.yml', '.tmcrc', 'metadata.yml'].include?(fn)
      true
    end

    def filter_file_for_stub(path)
      with_filter_backend_for(path) do |backend|
        backend.filter_for_stub(read_file_utf8(path))
      end
    end

    def filter_file_for_solution(path)
      with_filter_backend_for(path) do |backend|
        backend.filter_for_solution(read_file_utf8(path))
      end
    end

    def with_filter_backend_for(path, &block)
      backend = filter_backends.find {|b| b.applies_to?(path) }
      if backend
        block.call(backend)
      else
        read_file_utf8(path)
      end
    end

    def filter_backends
      @filter_backends ||= [
        CourseRefresher::JavaFilter.new,
        CourseRefresher::XmlFilter.new,
        CourseRefresher::PropertiesFilter.new,
        CourseRefresher::CssFilter.new,
        CourseRefresher::JsFilter.new,
        CourseRefresher::MakefileCFilter.new
      ]
    end

    def clean_empty_dirs_in_project(project_dir)
      clean_empty_dirs_under(project_dir + 'src') if (project_dir + 'src').directory?
      clean_empty_dirs_under(project_dir + 'test') if (project_dir + 'test').directory?
    end

    def clean_empty_dirs_under(dir)
      dir.children.each {|c| clean_empty_dirs(c) if c.directory? }
    end

    def clean_empty_dirs(dir)
      if dir.directory?
        clean_empty_dirs_under(dir)
        dir.rmdir if dir.children.empty?
      end
    end

    def maybe_write_html_file(text, dest_path)
      if text =~ prepended_html_regexp
        html = $1
        html.gsub!(/^[ \t*]*/, '')
        File.open(dest_path, 'wb') do |f|
          f.write(html)
        end
      end
    end

    def prepended_html_regexp
      CourseRefresher::JavaFilter.new.prepended_html_regexp
    end
  end
end
