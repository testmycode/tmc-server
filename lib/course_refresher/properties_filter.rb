require 'pathname'
require 'course_refresher/line_comment_based_filter'

class CourseRefresher
  class PropertiesFilter < LineCommentBasedFilter
    def applies_to?(file_path)
      Pathname(file_path).extname == '.properties'
    end

    def comment_start
      '#'
    end
  end
end
