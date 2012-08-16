require 'pathname'

class CourseRefresher
  class JavaFilter
    def applies_to?(file_path)
      Pathname(file_path).extname == '.java'
    end

    def filter_for_stub(text)
      return nil if text =~ solution_file_regexp
      text = fix_line_endings(text)
      text = remove_solution_blocks(text)
      text = uncomment_stubs(text)
      text = remove_html_comments(text)
      text
    end

    def filter_for_solution(text)
      text = fix_line_endings(text)
      text = remove_stub_and_solution_comments(text)
      text = remove_html_comments(text)
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
        before + after
      end
    end

    def remove_html_comments(text)
      text.gsub(prepended_html_regexp, '')
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
