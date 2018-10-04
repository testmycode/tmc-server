class RenameCacheVersion < ActiveRecord::Migration
  def change
    rename_column :courses, :cache_version, :cached_version
    rename_column :course_templates, :cache_version, :cached_version
  end
end
