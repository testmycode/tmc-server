class RemoveUserIdFromFeedbackAnswers < ActiveRecord::Migration[4.2]
  def change
    remove_column :feedback_answers, :user_id
  end
end
