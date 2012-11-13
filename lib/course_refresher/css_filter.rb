require 'pathname'
require 'course_refresher/block_comment_based_filter'

class CourseRefresher
  class CssFilter < BlockCommentBasedFilter
    def applies_to?(file_path)
      Pathname(file_path).extname == '.css'
    end

    def comment_begin
      "/*"
    end

    def comment_end
      "*/"
    end
  end
end
