class AddTitleToFeedbackQuestions < ActiveRecord::Migration
  def change
    add_column :feedback_questions, :title, :text, :null => true
  end
end
