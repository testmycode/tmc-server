require 'pathname'
require 'course_refresher/line_based_filter'

class CourseRefresher
  class CssFilter
    #TODO: refactor

    def applies_to?(file_path)
      Pathname(file_path).extname == '.css'
    end

    def filter_for_stub(text)
      return nil if text =~ solution_file_regexp
      #TODO: text = fix_line_endings(text)
      #TODO: text = remove_solution_blocks(text)
      #TODO: text = uncomment_stubs(text)
      text
    end

    def filter_for_solution(text)
      #TODO: text = fix_line_endings(text)
      #TODO: text = remove_stub_and_solution_comments(text)
      text
    end

    def solution_file_regexp
      /\/\*[ \t\n]*SOLUTION[ \t\n]+FILE[ \t\n]*\*\//m
    end
  end
end
