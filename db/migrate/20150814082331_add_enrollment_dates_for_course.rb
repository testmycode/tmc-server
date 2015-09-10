class AddEnrollmentDatesForCourse < ActiveRecord::Migration
  def change
    add_column :courses, :enrollment_begins_at, :datetime
    add_column :courses, :enrollment_ends_at, :datetime
  end
end
