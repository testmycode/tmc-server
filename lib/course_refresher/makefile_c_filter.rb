require 'pathname'
require 'course_refresher/line_comment_based_filter'

class CourseRefresher
  class MakefileCFilter < BlockCommentBasedFilter
    def applies_to?(file_path)
      %w(.c .h).include? Pathname(file_path).extname
    end

    def filter_for_stub(text)
      text = super(text)
      if text
        remove_html_comments(text)
      else
        nil
      end
    end

    def filter_for_solution(text)
      text = super(text)
      if text
        remove_html_comments(text)
      else
        nil
      end
    end

    def remove_html_comments(text)
      text.gsub(prepended_html_regexp, '')
    end

    def prepended_html_regexp #needed?
      /^[ \t]*\/\*[ t*\r\n]*PREPEND[ \t]+HTML[ \t]*((?:[*][^\/]|[^*])*)\*\/[ \t]*\n/m
    end

    def comment_begin
      "/*"
    end

    def comment_end
      "*/"
    end
  end
end
