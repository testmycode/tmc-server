class AddUniqueRequirementForMigratedSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_index :migrated_submissions, [:from_course_id, :to_course_id, :original_submission_id, :new_submission_id], unique: true, name: "unique_values"
  end
end
