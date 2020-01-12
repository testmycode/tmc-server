class AddSubmissionsCountToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :submissions_count, :integer, default: 0, null: false
  end
end
