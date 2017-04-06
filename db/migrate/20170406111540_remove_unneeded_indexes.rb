class RemoveUnneededIndexes < ActiveRecord::Migration
  def change
    remove_index :feedback_questions, name: 'index_feedback_questions_on_id'
  end
end
