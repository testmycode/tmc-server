class AddMoreMissingIndexes < ActiveRecord::Migration
  def change
    add_index :action_tokens, :user_id
    add_index :certificates, :course_id
    add_index :certificates, :user_id
    add_index :course_notifications, :course_id
    add_index :courses, :course_template_id
    add_index :feedback_questions, :course_id
    add_index :model_solution_access_logs, :course_id
    add_index :model_solution_access_logs, :user_id
    add_index :oauth_access_grants, :application_id
    add_index :oauth_access_tokens, :application_id
    add_index :organizations, :creator_id
    add_index :reply_to_feedback_answers, :feedback_answer_id
    add_index :verification_tokens, :user_id
  end
end
