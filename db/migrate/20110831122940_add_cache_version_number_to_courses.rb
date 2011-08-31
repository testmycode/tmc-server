class AddCacheVersionNumberToCourses < ActiveRecord::Migration
  def self.up
    add_column :courses, :cache_version, :int, :null => false, :default => 0
  end

  def self.down
    remove_column :courses, :cache_version
  end
end
