class FixExerciseNameTypeInFeedbackAnswers < ActiveRecord::Migration
  def up
    change_column :feedback_answers, :exercise_name, :string, :null => false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
