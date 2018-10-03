class IndexSubmissionsByCourseIdAndUserId < ActiveRecord::Migration[4.2]
  def change
    add_index :submissions, [:course_id, :user_id]
  end
end
