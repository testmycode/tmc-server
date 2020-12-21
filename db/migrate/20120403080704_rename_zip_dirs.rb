require 'pathname'
require 'fileutils'

class RenameZipDirs < ActiveRecord::Migration[4.2]
  def up
    for_each_course_dir do |course_dir|
      FileUtils.mv(course_dir + 'zip', course_dir + 'stub_zip') if (course_dir + 'zip').directory?
    end
  end

  def down
    for_each_course_dir do |course_dir|
      FileUtils.mv(course_dir + 'stub_zip', course_dir + 'zip') if (course_dir + 'stub_zip').directory?
    end
  end

private
  def for_each_course_dir(&block)
    root = Pathname(Course.cache_root)
    if root.directory?
      for course_dir in root.children.select(&:directory?)
        block.call(course_dir)
      end
    end
  end
end
