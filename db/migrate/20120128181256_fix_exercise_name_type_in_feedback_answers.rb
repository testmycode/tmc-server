class FixExerciseNameTypeInFeedbackAnswers < ActiveRecord::Migration[4.2]
  def up
    change_column :feedback_answers, :exercise_name, :string, null: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
