class MigratedSubmissionsMigrations < ActiveRecord::Migration[4.2]
  def change
    create_table :migrated_submissions, :id => false do |t|
      t.integer :from_course_id
      t.integer :to_course_id
      t.integer :original_submission_id
      t.integer :new_submission_id

      t.timestamps null: false
    end
  end
end
