# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2024_02_26_094608) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_tokens", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.integer "action", null: false
    t.datetime "expires_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_action_tokens_on_user_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assistantships", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id", "course_id"], name: "index_assistantships_on_user_id_and_course_id", unique: true
  end

  create_table "available_points", id: :serial, force: :cascade do |t|
    t.integer "exercise_id", null: false
    t.string "name", null: false
    t.boolean "requires_review", default: false, null: false
    t.index ["exercise_id", "name"], name: "index_available_points_on_exercise_id_and_name", unique: true
  end

  create_table "awarded_points", id: :serial, force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "user_id", null: false
    t.integer "submission_id"
    t.string "name", null: false
    t.datetime "created_at"
    t.boolean "awarded_after_soft_deadline", default: false, null: false
    t.index ["course_id", "user_id", "name"], name: "index_awarded_points_on_course_id_and_user_id_and_name", unique: true
    t.index ["course_id", "user_id", "submission_id"], name: "index_awarded_points_on_course_id_and_user_id_and_submission_id"
    t.index ["user_id", "submission_id", "name"], name: "index_awarded_points_on_user_id_and_submission_id_and_name", unique: true
  end

  create_table "banned_emails", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "certificates", id: :serial, force: :cascade do |t|
    t.string "name"
    t.binary "pdf"
    t.integer "user_id"
    t.integer "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["course_id"], name: "index_certificates_on_course_id"
    t.index ["user_id"], name: "index_certificates_on_user_id"
  end

  create_table "course_notifications", id: :serial, force: :cascade do |t|
    t.string "topic"
    t.string "message"
    t.integer "sender_id"
    t.integer "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["course_id"], name: "index_course_notifications_on_course_id"
  end

  create_table "course_template_refresh_phases", id: :serial, force: :cascade do |t|
    t.string "phase_name", null: false
    t.integer "time_ms", null: false
    t.integer "course_template_refresh_id", null: false
    t.index ["course_template_refresh_id"], name: "index_course_refresh_phases_on_course_template_refresh_id"
  end

  create_table "course_template_refresh_reports", force: :cascade do |t|
    t.text "refresh_errors"
    t.text "refresh_warnings"
    t.text "refresh_notices"
    t.text "refresh_timings"
    t.bigint "course_template_refresh_id", null: false
    t.index ["course_template_refresh_id"], name: "index_course_refresh_reports_on_course_template_refresh_id"
  end

  create_table "course_template_refreshes", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "status", default: 0, null: false
    t.decimal "percent_done", precision: 10, scale: 4, default: "0.0", null: false
    t.jsonb "langs_refresh_output"
    t.integer "user_id", null: false
    t.integer "course_template_id", null: false
    t.index ["course_template_id"], name: "index_course_template_refreshes_on_course_template_id"
    t.index ["user_id"], name: "index_course_template_refreshes_on_user_id"
  end

  create_table "course_templates", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "description"
    t.string "material_url"
    t.string "source_url"
    t.boolean "dummy", default: false, null: false
    t.boolean "hidden", default: false
    t.integer "cached_version", default: 0, null: false
    t.string "source_backend", default: "git", null: false
    t.string "git_branch", default: "master", null: false
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "courses", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "hide_after"
    t.boolean "hidden", default: false, null: false
    t.integer "cached_version", default: 0, null: false
    t.string "spreadsheet_key"
    t.datetime "hidden_if_registered_after"
    t.datetime "refreshed_at"
    t.boolean "locked_exercise_points_visible", default: true, null: false
    t.text "description"
    t.integer "paste_visibility"
    t.string "formal_name"
    t.boolean "certificate_downloadable", default: false, null: false
    t.string "certificate_unlock_spec"
    t.integer "organization_id"
    t.integer "disabled_status", default: 1
    t.string "title"
    t.string "material_url"
    t.integer "course_template_id", null: false
    t.boolean "hide_submission_results", default: false
    t.string "external_scoreboard_url"
    t.boolean "initial_refresh_ready", default: false
    t.boolean "hide_submissions", default: false, null: false
    t.boolean "model_solution_visible_before_completion", default: false, null: false
    t.float "soft_deadline_point_multiplier", default: 0.75, null: false
    t.boolean "code_review_requests_enabled", default: true, null: false
    t.integer "grant_model_solution_token_every_nth_completed_exercise"
    t.integer "initial_coin_stash"
    t.boolean "large_exercises_consume_more_coins", default: false
    t.string "moocfi_id"
    t.integer "submissions_count", default: 0, null: false
    t.index ["course_template_id"], name: "index_courses_on_course_template_id"
    t.index ["organization_id"], name: "index_courses_on_organization_id"
  end

  create_table "exercises", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "course_id"
    t.datetime "publish_time"
    t.string "gdocs_sheet"
    t.boolean "hidden", default: false, null: false
    t.boolean "returnable_forced"
    t.string "checksum", default: "", null: false
    t.datetime "solution_visible_after"
    t.boolean "has_tests", default: false, null: false
    t.text "deadline_spec"
    t.text "unlock_spec"
    t.string "runtime_params", default: "[]", null: false
    t.string "valgrind_strategy"
    t.boolean "code_review_requests_enabled", default: false, null: false
    t.boolean "run_tests_locally_action_enabled", default: true, null: false
    t.text "soft_deadline_spec"
    t.integer "disabled_status", default: 0
    t.boolean "hide_submission_results", default: false
    t.string "docker_image", default: "eu.gcr.io/moocfi-public/tmc-sandbox-tmc-langs-rust"
    t.integer "paste_visibility"
    t.integer "memory_limit_gb", default: 1, null: false
    t.integer "cpu_limit", default: 1, null: false
    t.index ["course_id", "name"], name: "index_exercises_on_course_id_and_name", unique: true
    t.index ["gdocs_sheet"], name: "index_exercises_on_gdocs_sheet"
    t.index ["name"], name: "index_exercises_on_name"
  end

  create_table "feedback_answers", id: :serial, force: :cascade do |t|
    t.integer "feedback_question_id", null: false
    t.integer "course_id", null: false
    t.string "exercise_name", null: false
    t.integer "submission_id"
    t.text "answer", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["feedback_question_id", "course_id", "exercise_name"], name: "index_feedback_answers_question_course_exercise"
    t.index ["submission_id"], name: "index_feedback_answers_question"
  end

  create_table "feedback_questions", id: :serial, force: :cascade do |t|
    t.integer "course_id", null: false
    t.text "question", null: false
    t.string "kind", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "position", null: false
    t.text "title"
    t.index ["course_id"], name: "index_feedback_questions_on_course_id"
  end

  create_table "kafka_batch_update_points", id: :serial, force: :cascade do |t|
    t.integer "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "exercise_id"
    t.string "task_type", default: "progress", null: false
    t.boolean "realtime", default: true
    t.index ["course_id"], name: "index_kafka_batch_update_points_on_course_id"
  end

  create_table "migrated_submissions", id: false, force: :cascade do |t|
    t.integer "from_course_id"
    t.integer "to_course_id"
    t.integer "original_submission_id"
    t.integer "new_submission_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_course_id", "to_course_id", "original_submission_id", "new_submission_id"], name: "unique_values", unique: true
  end

  create_table "model_solution_access_logs", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.string "exercise_name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["course_id"], name: "index_model_solution_access_logs_on_course_id"
    t.index ["user_id"], name: "index_model_solution_access_logs_on_user_id"
  end

  create_table "model_solution_token_useds", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "course_id"
    t.string "exercise_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cost", default: 1, null: false
    t.index ["course_id"], name: "index_model_solution_token_useds_on_course_id"
    t.index ["user_id"], name: "index_model_solution_token_useds_on_user_id"
  end

  create_table "oauth_access_grants", id: :serial, force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :serial, force: :cascade do |t|
    t.integer "resource_owner_id"
    t.integer "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "confidential", default: true, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_openid_requests", force: :cascade do |t|
    t.bigint "access_grant_id", null: false
    t.string "nonce", null: false
    t.index ["access_grant_id"], name: "index_oauth_openid_requests_on_access_grant_id"
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "organization_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_organization_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "information"
    t.string "slug"
    t.datetime "verified_at"
    t.boolean "verified"
    t.boolean "disabled", default: false, null: false
    t.string "disabled_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "hidden", default: false
    t.integer "creator_id"
    t.string "logo_file_name"
    t.string "logo_content_type"
    t.integer "logo_file_size"
    t.datetime "logo_updated_at"
    t.string "phone"
    t.text "contact_information"
    t.string "email"
    t.text "website"
    t.boolean "pinned", default: false, null: false
    t.string "whitelisted_ips", array: true
    t.index ["creator_id"], name: "index_organizations_on_creator_id"
  end

  create_table "points_upload_queues", id: :serial, force: :cascade do |t|
    t.integer "point_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recently_changed_user_details", id: :serial, force: :cascade do |t|
    t.integer "change_type", null: false
    t.string "old_value"
    t.string "new_value", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "username"
    t.string "email"
    t.integer "user_id"
    t.index ["user_id"], name: "index_recently_changed_user_details_on_user_id"
  end

  create_table "reply_to_feedback_answers", id: :serial, force: :cascade do |t|
    t.integer "feedback_answer_id"
    t.text "body"
    t.string "from"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["feedback_answer_id"], name: "index_reply_to_feedback_answers_on_feedback_answer_id"
  end

  create_table "reviews", id: :serial, force: :cascade do |t|
    t.integer "submission_id", null: false
    t.integer "reviewer_id"
    t.text "review_body", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "points"
    t.boolean "marked_as_read", default: false, null: false
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
    t.index ["submission_id"], name: "index_reviews_on_submission_id"
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "submission_data", primary_key: "submission_id", id: :integer, default: nil, force: :cascade do |t|
    t.binary "return_file"
    t.binary "stdout_compressed"
    t.binary "stderr_compressed"
    t.binary "vm_log_compressed"
    t.binary "valgrind_compressed"
    t.binary "validations_compressed"
  end

  create_table "submissions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "pretest_error"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "exercise_name", null: false
    t.integer "course_id", null: false
    t.boolean "processed", default: false, null: false
    t.string "secret_token"
    t.boolean "all_tests_passed", default: false, null: false
    t.text "points"
    t.datetime "processing_tried_at"
    t.datetime "processing_began_at"
    t.datetime "processing_completed_at"
    t.integer "times_sent_to_sandbox", default: 0, null: false
    t.datetime "processing_attempts_started_at"
    t.integer "processing_priority", default: 0, null: false
    t.text "params_json"
    t.boolean "requires_review", default: false, null: false
    t.boolean "requests_review", default: false, null: false
    t.boolean "reviewed", default: false, null: false
    t.text "message_for_reviewer", default: "", null: false
    t.boolean "newer_submission_reviewed", default: false, null: false
    t.boolean "review_dismissed", default: false, null: false
    t.boolean "paste_available", default: false, null: false
    t.text "message_for_paste"
    t.string "paste_key"
    t.datetime "client_time"
    t.bigint "client_nanotime"
    t.text "client_ip"
    t.string "sandbox"
    t.index ["course_id", "created_at"], name: "index_submissions_on_course_id_and_created_at"
    t.index ["course_id", "exercise_name"], name: "index_submissions_on_course_id_and_exercise_name"
    t.index ["course_id", "requires_review", "requests_review"], name: "index_submissions_on_course_id_and_reviews"
    t.index ["course_id", "user_id"], name: "index_submissions_on_course_id_and_user_id"
    t.index ["exercise_name"], name: "index_submissions_on_exercise_name"
    t.index ["paste_key"], name: "index_submissions_on_paste_key"
    t.index ["processed"], name: "index_submissions_on_processed"
    t.index ["user_id", "exercise_name"], name: "index_submissions_on_user_id_and_exercise_name"
  end

  create_table "teacherships", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id", "organization_id"], name: "index_teacherships_on_user_id_and_organization_id", unique: true
  end

  create_table "test_case_runs", id: :serial, force: :cascade do |t|
    t.integer "submission_id"
    t.text "test_case_name"
    t.text "message"
    t.boolean "successful"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "exception"
    t.text "detailed_message"
    t.index ["submission_id"], name: "index_test_case_runs_on_submission_id"
  end

  create_table "test_scanner_cache_entries", id: :serial, force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "exercise_name"
    t.string "files_hash"
    t.text "value"
    t.datetime "created_at"
    t.index ["course_id", "exercise_name"], name: "index_test_scanner_cache_entries_on_course_id_and_exercise_name", unique: true
  end

  create_table "uncomputed_unlocks", id: :serial, force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["course_id", "user_id"], name: "index_uncomputed_unlocks_on_course_id_and_user_id"
  end

  create_table "unlocks", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.string "exercise_name", null: false
    t.datetime "valid_after"
    t.datetime "created_at", null: false
    t.index ["user_id", "course_id", "exercise_name"], name: "index_unlocks_on_user_id_and_course_id_and_exercise_name", unique: true
  end

  create_table "user_app_data", id: :serial, force: :cascade do |t|
    t.string "field_name"
    t.text "value"
    t.string "namespace"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id", "field_name", "namespace"], name: "index_user_app_data_on_user_id_and_field_name_and_namespace", unique: true
  end

  create_table "user_field_values", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "field_name", null: false
    t.text "value", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id", "field_name"], name: "index_user_field_values_on_user_id_and_field_name", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "login", null: false
    t.text "password_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "salt"
    t.boolean "administrator", default: false, null: false
    t.text "email", default: "", null: false
    t.boolean "legitimate_student", default: true, null: false
    t.boolean "email_verified", default: false, null: false
    t.string "argon_hash"
    t.index "lower(email)", name: "index_user_email_lowercase", unique: true
    t.index ["login"], name: "index_users_on_login", unique: true
  end

  create_table "verification_tokens", id: :serial, force: :cascade do |t|
    t.string "token", null: false
    t.integer "type", null: false
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_verification_tokens_on_user_id"
  end

  add_foreign_key "action_tokens", "users", on_delete: :cascade
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "available_points", "exercises", on_delete: :cascade
  add_foreign_key "awarded_points", "courses", on_delete: :cascade
  add_foreign_key "awarded_points", "submissions", on_delete: :nullify
  add_foreign_key "awarded_points", "users", on_delete: :cascade
  add_foreign_key "course_template_refresh_phases", "course_template_refreshes"
  add_foreign_key "course_template_refresh_reports", "course_template_refreshes"
  add_foreign_key "course_template_refreshes", "course_templates"
  add_foreign_key "course_template_refreshes", "users"
  add_foreign_key "courses", "organizations"
  add_foreign_key "exercises", "courses", on_delete: :cascade
  add_foreign_key "feedback_answers", "feedback_questions", on_delete: :cascade
  add_foreign_key "feedback_answers", "submissions", on_delete: :nullify
  add_foreign_key "feedback_questions", "courses", on_delete: :cascade
  add_foreign_key "kafka_batch_update_points", "courses"
  add_foreign_key "model_solution_token_useds", "courses"
  add_foreign_key "model_solution_token_useds", "users"
  add_foreign_key "oauth_openid_requests", "oauth_access_grants", column: "access_grant_id", on_delete: :cascade
  add_foreign_key "reviews", "submissions", on_delete: :cascade
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "submission_data", "submissions", on_delete: :cascade
  add_foreign_key "submissions", "courses", on_delete: :cascade
  add_foreign_key "submissions", "users", on_delete: :cascade
  add_foreign_key "test_case_runs", "submissions", on_delete: :cascade
  add_foreign_key "test_scanner_cache_entries", "courses", on_delete: :cascade
  add_foreign_key "user_app_data", "users"
  add_foreign_key "user_field_values", "users", on_delete: :cascade
end
