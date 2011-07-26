class SoftRelationshipBetweenSubmissionAndExercise < ActiveRecord::Migration
  def self.up
    add_column :submissions, :exercise_name, :string
    add_column :submissions, :course_id, :int
    execute "UPDATE submissions SET exercise_name = (SELECT name FROM exercises WHERE id = exercise_id)"
    execute "UPDATE submissions SET course_id = (SELECT course_id FROM exercises WHERE id = exercise_id)"
    change_column :submissions, :course_id, :int, :null => false, :limit => false
    change_column :submissions, :exercise_name, :string, :null => false, :limit => false
    remove_column :submissions, :exercise_id
    remove_column :exercises, :deleted
    
    add_index :exercises, [:name]
    add_index :submissions, [:course_id, :exercise_name]
  end

  def self.down
    raise 'Irreversible'
  end
end
