class AddInitialRefreshReadyToCourse < ActiveRecord::Migration[4.2]
  def up
    add_column :courses, :initial_refresh_ready, :boolean, default: false
    Course.update_all(initial_refresh_ready: true)
  end

  def down
    remove_column :courses, :initial_refresh_ready
  end
end
