require 'pathname'
require 'course_refresher/block_comment_based_filter'

class CourseRefresher
  class XmlFilter < BlockCommentBasedFilter
    def applies_to?(file_path)
      ['.xml', '.jsp', '.html'].include?(Pathname(file_path).extname)
    end

    def comment_begin
      '<!--'
    end

    def comment_end
      '-->'
    end
  end
end
