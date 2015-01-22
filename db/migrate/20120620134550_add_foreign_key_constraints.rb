class AddForeignKeyConstraints < ActiveRecord::Migration
  def change
    add_foreign_key "exercises", "courses", dependent: :delete
    add_foreign_key "submissions", "courses", dependent: :delete
    add_foreign_key "awarded_points", "courses", dependent: :delete
    add_foreign_key "test_scanner_cache_entries", "courses", dependent: :delete
    add_foreign_key "feedback_questions", "courses", dependent: :delete
    add_foreign_key "student_events", "courses", dependent: :delete

    add_foreign_key "available_points", "exercises", dependent: :delete

    add_foreign_key "feedback_answers", "feedback_questions", dependent: :delete

    add_foreign_key "submissions", "users", dependent: :delete
    add_foreign_key "awarded_points", "users", dependent: :delete
    add_foreign_key "password_reset_keys", "users", dependent: :delete
    add_foreign_key "user_field_values", "users", dependent: :delete
    add_foreign_key "student_events", "users", dependent: :delete

    add_foreign_key "test_case_runs", "submissions", dependent: :delete
    add_foreign_key "awarded_points", "submissions", dependent: :nullify
    add_foreign_key "feedback_answers", "submissions", dependent: :nullify
  end
end
