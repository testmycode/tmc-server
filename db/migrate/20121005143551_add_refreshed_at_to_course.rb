class AddRefreshedAtToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :refreshed_at, :datetime
  end
end
