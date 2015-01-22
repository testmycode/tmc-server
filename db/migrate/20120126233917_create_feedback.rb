class CreateFeedback < ActiveRecord::Migration
  def change
    create_table :feedback_questions do |t|
      t.integer :course_id, null: false
      t.text :question, null: false
      t.string :kind, null: false
      t.timestamps
    end

    create_table :feedback_answers do |t|
      t.integer :feedback_question_id, null: false
      t.integer :user_id, null: false
      t.integer :course_id, null: false
      t.integer :exercise_name, null: false
      t.integer :submission_id, null: true
      t.text :answer, null: false
      t.timestamps
    end

    add_index :feedback_answers, [:feedback_question_id, :course_id, :exercise_name], name: 'index_feedback_answers_question_course_exercise'
    add_index :feedback_answers, [:feedback_question_id, :course_id, :user_id], name: 'index_feedback_answers_question_course_user'
    add_index :feedback_answers, [:submission_id], name: 'index_feedback_answers_question'
  end
end
