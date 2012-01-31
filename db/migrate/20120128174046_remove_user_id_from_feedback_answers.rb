class RemoveUserIdFromFeedbackAnswers < ActiveRecord::Migration
  def change
    remove_column :feedback_answers, :user_id
  end
end
