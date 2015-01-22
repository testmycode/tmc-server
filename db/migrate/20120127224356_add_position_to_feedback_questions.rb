class AddPositionToFeedbackQuestions < ActiveRecord::Migration
  def up
    add_column :feedback_questions, :position, :int
    execute "UPDATE feedback_questions SET position = id"
    change_column :feedback_questions, :position, :int, null: false
  end

  def down
    remove_column :feedback_questions, :position
  end
end
