class AddInitialRefreshReadyToCourse < ActiveRecord::Migration
  def up
    add_column :courses, :initial_refresh_ready, :boolean, default: false
    Course.all.each do |c|
      c.initial_refresh_ready = true
      c.save!
    end
  end

  def down
    remove_column :courses, :initial_refresh_ready
  end
end
