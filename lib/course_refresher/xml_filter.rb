require 'pathname'

class CourseRefresher
  class XmlFilter
    def applies_to?(file_path)
      ['.xml', '.jsp', '.html'].include?(Pathname(file_path).extname)
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

    def remove_stub_and_solution_comments(text)
      for regex in [stub_regexp, begin_solution_regexp, end_solution_regexp, solution_file_regexp]
        while text =~ regex
          text = $~.pre_match + $~.post_match
        end
      end
      text
    end

    def stub_regexp
      /(\n?[ \t]*)<!--[ \n\t]*STUB:[ \n\t]*(.*?)[ \n\t]*-->[ \t]*/m
    end

    def begin_solution_regexp
      /[ \t]*<!--[ \t]*BEGIN[ \t]+SOLUTION[ \t]*-->[ \t]*\n?/m
    end

    def end_solution_regexp
      /[ \t]*<!--[ \t]*END[ \t]+SOLUTION[ \t]*-->[ \t]*\n?/m
    end

    def solution_file_regexp
      /<!--[ \t]*SOLUTION[ \t]+FILE[ \n\t]*-->[ \t]*\n?/m
    end
  end
end
