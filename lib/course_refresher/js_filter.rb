# frozen_string_literal: true

require 'pathname'
require 'course_refresher/line_comment_based_filter'

class CourseRefresher
  class JsFilter < LineCommentBasedFilter
    def applies_to?(file_path)
      Pathname(file_path).extname == '.js'
    end

    def comment_start
      '//'
    end
  end
end
