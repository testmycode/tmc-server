class AddRefreshStartedAtToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :refresh_started_at, :datetime
  end
end
