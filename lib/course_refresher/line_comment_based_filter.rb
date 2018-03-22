require 'pathname'

class CourseRefresher
  class LineCommentBasedFilter # Abstract
    def applies_to?(_file_path)
      raise 'abstract method'
    end

    def filter_for_stub(text)
      return nil if text =~ solution_file_regexp
      text = fix_line_endings(text)
      text = remove_solution_blocks(text)
      text = uncomment_stubs(text)
      text
    end

    def filter_for_solution(text)
      text = fix_line_endings(text)
      text = remove_stub_and_solution_comments(text)
      text
    end

    def fix_line_endings(text)
      text.delete("\r")
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
        before = Regexp.last_match(1)
        after = Regexp.last_match(2)
        before + after
      end
    end

    def remove_stub_and_solution_comments(text)
      result = []
      text.lines.each do |line|
        match = [stub_regexp, begin_solution_regexp, end_solution_regexp, solution_file_regexp].any? do |regexp|
          line =~ regexp
        end
        result << line unless match
      end
      result.join('')
    end

    def stub_regexp
      /^([ \t]*)#{resc comment_start}[ \t]*STUB:[ \t]*([^\r\n]*)$/m
    end

    def begin_solution_regexp
      /^[ \t]*#{resc comment_start}[ \t]*BEGIN[ \t]+SOLUTION[ \t]*$/m
    end

    def end_solution_regexp
      /^[ \t]*#{resc comment_start}[ \t]*END[ \t]+SOLUTION[ \t]*\n/m
    end

    def solution_file_regexp
      /#{resc comment_start}[ \t]*SOLUTION[ \t]+FILE[ \t]*/
    end

    def comment_start
      raise 'abstract method'
    end

    def resc(s)
      Regexp.escape(s)
    end
  end
end
