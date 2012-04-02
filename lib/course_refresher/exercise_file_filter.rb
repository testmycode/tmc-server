require 'pathname'
require 'fileutils'
require 'tmc_project_file'

class CourseRefresher
  class ExerciseFileFilter
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
        contents = filter_for_stub(from)
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
        contents = filter_for_solution(from)
        write_file(to, contents) unless contents.nil?
        maybe_write_html_file(File.read(from), "#{to}.html") if from.extname == '.java'
      end

      clean_empty_dirs_in_project(to_dir)
    end
    
  private
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
      !(fn.include?('Hidden') || fn.start_with?('.git') || fn == 'metadata.yml' || fn == '.tmcrc')
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
    
    
    def filter_for_stub(source_path)
      text = File.read(source_path)
      if source_path.extname == '.java'
        return nil if text =~ solution_file_regexp
        text = fix_line_endings(text)
        text = remove_solution_blocks(text)
        text = uncomment_stubs(text)
        text = remove_html_comments(text)
      end
      text
    end
    
    def fix_line_endings(text)
      text.gsub("\r", "")
    end
    
    def remove_solution_blocks(text)
      result = ''
      remaining = text
      in_block = false
      
      while remaining
        if !in_block && remaining =~ begin_solution_regexp
          result += $~.pre_match
          remaining = $~.post_match
          in_block = true
        elsif in_block && remaining =~ end_solution_regexp
          remaining = $~.post_match
          in_block = false
        else
          if !in_block
            result += remaining
          else
            # TODO: warn about unclosed begin solution block
          end
          remaining = nil
        end
      end
      
      result
    end
    
    def uncomment_stubs(text)
      text.gsub(stub_regexp) do
        before = $1
        after = $2
        before.gsub(/[^\t]/, ' ') + after
      end
    end

    def remove_html_comments(text)
      text.gsub(prepended_html_regexp, '')
    end
    
    
    def filter_for_solution(source_path)
      text = File.read(source_path)
      if source_path.extname == '.java'
        text = fix_line_endings(text)
        text = remove_stub_and_solution_comments(text)
        text = remove_html_comments(text)
      end
      text
    end
    
    def remove_stub_and_solution_comments(text)
      result = []
      for line in text.lines
        match = [stub_regexp, begin_solution_regexp, end_solution_regexp, solution_file_regexp].any? do |regexp|
          line =~ regexp
        end
        result << line unless match
      end
      result.join('')
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

    
    def stub_regexp
      /^([ \t]*)\/\/[ \t]*STUB:[ \t]*([^\r\n]*)$/m
    end
    
    def begin_solution_regexp
      /^[ \t]*\/\/[ \t]*BEGIN[ \t]+SOLUTION[ \t]*$/m
    end
    
    def end_solution_regexp
      /^[ \t]*\/\/[ \t]*END[ \t]+SOLUTION[ \t]*\n/m
    end
    
    def solution_file_regexp
      /\/\/[ \t]*SOLUTION[ \t]+FILE[ \t]*/
    end

    def prepended_html_regexp
      /^[ \t]*\/\*[ t*\r\n]*PREPEND[ \t]+HTML[ \t]*((?:[*][^\/]|[^*])*)\*\/[ \t]*\n/m
    end
  end
end

