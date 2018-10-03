class AddTitleToFeedbackQuestions < ActiveRecord::Migration[4.2]
  def change
    add_column :feedback_questions, :title, :text, null: true
  end
end
