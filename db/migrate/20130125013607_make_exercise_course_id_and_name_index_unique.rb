class MakeExerciseCourseIdAndNameIndexUnique < ActiveRecord::Migration
  def up
    remove_index "exercises", ["course_id", "name"]
    add_index "exercises", ["course_id", "name"], unique: true
  end

  def down
    remove_index "exercises", ["course_id", "name"]
    add_index "exercises", ["course_id", "name"]
  end
end
