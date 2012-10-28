require 'pathname'
require 'course_refresher/line_based_filter'

class CourseRefresher
  class JsFilter < LineBasedFilter
    def applies_to?(file_path)
      Pathname(file_path).extname == '.js'
    end

    def comment_start
      '//'
    end
  end
end
