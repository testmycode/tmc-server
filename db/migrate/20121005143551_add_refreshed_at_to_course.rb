class AddRefreshedAtToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :refreshed_at, :datetime
  end
end
