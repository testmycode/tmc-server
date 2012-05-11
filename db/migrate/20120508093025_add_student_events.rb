class AddStudentEvents < ActiveRecord::Migration
  def change
    create_table :student_events do |t|
      t.integer :user_id, :null => false
      t.integer :course_id, :null => false
      t.string :exercise_name, :null => false
      t.string :event_type, :null => false
      t.binary :data, :null => false
      t.datetime :happened_at, :null => false
    end
    add_index(:student_events, [:user_id, :event_type, :happened_at], :name => 'index_student_events_user_type_time')
    add_index(:student_events, [:user_id, :course_id, :exercise_name, :event_type, :happened_at], :name => 'index_student_events_user_course_exercise_type_time')
  end
end
