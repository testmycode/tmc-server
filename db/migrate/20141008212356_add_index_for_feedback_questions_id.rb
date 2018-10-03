class AddIndexForFeedbackQuestionsId < ActiveRecord::Migration[4.2]
  def change
    add_index :feedback_questions, [:id]
  end
end
