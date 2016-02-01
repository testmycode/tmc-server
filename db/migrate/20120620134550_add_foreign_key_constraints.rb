class AddForeignKeyConstraints < ActiveRecord::Migration
  def change
    add_foreign_key "exercises", "courses", on_delete: :cascade
    add_foreign_key "submissions", "courses", on_delete: :cascade
    add_foreign_key "awarded_points", "courses", on_delete: :cascade
    add_foreign_key "test_scanner_cache_entries", "courses", on_delete: :cascade
    add_foreign_key "feedback_questions", "courses", on_delete: :cascade
    add_foreign_key "student_events", "courses", on_delete: :cascade

    add_foreign_key "available_points", "exercises", on_delete: :cascade

    add_foreign_key "feedback_answers", "feedback_questions", on_delete: :cascade

    add_foreign_key "submissions", "users", on_delete: :cascade
    add_foreign_key "awarded_points", "users", on_delete: :cascade
    add_foreign_key "password_reset_keys", "users", on_delete: :cascade
    add_foreign_key "user_field_values", "users", on_delete: :cascade
    add_foreign_key "student_events", "users", on_delete: :cascade

    add_foreign_key "test_case_runs", "submissions", on_delete: :cascade
    add_foreign_key "awarded_points", "submissions", on_delete: :nullify
    add_foreign_key "feedback_answers", "submissions", on_delete: :nullify
  end
end
