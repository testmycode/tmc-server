class AddCourseIdAndNameIndexToExercises < ActiveRecord::Migration
  def up
    remove_index "exercises", name: "index_exercises_on_name"
    add_index "exercises", ["course_id", "name"], name: "index_exercises_on_course_id_and_name"
  end
  def down
    remove_index "exercises", name: "index_exercises_on_course_id_and_name"
    add_index "exercises", ["name"], name: "index_exercises_on_name"
  end
end
