require 'pathname'
require 'course_refresher/line_based_filter'

class CourseRefresher
  class PropertiesFilter < LineBasedFilter
    def applies_to?(file_path)
      Pathname(file_path).extname == '.properties'
    end

    def comment_start
      '#'
    end
  end
end
