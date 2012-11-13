class IndexSubmissionsByCourseIdAndUserId < ActiveRecord::Migration
  def change
    add_index :submissions, [:course_id, :user_id]
  end
end
