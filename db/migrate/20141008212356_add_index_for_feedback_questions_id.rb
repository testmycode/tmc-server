class AddIndexForFeedbackQuestionsId < ActiveRecord::Migration
  def change
    add_index :feedback_questions, [:id]
  end
end
