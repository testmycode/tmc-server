class AddHideAfterToCourse < ActiveRecord::Migration
  def self.up
    add_column :courses, :hide_after, :datetime
  end

  def self.down
    remove_column :courses, :hide_after
  end
end
