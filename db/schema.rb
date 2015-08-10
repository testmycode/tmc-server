# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150727080841) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assistantships", force: true do |t|
    t.integer  "user_id"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assistantships", ["user_id", "course_id"], name: "index_assistantships_on_user_id_and_course_id", unique: true, using: :btree

  create_table "available_points", force: true do |t|
    t.integer "exercise_id",                     null: false
    t.string  "name",                            null: false
    t.boolean "requires_review", default: false, null: false
  end

  add_index "available_points", ["exercise_id", "name"], name: "index_available_points_on_exercise_id_and_name", unique: true, using: :btree

  create_table "awarded_points", force: true do |t|
    t.integer "course_id",     null: false
    t.integer "user_id",       null: false
    t.integer "submission_id"
    t.string  "name",          null: false
  end

  add_index "awarded_points", ["course_id", "user_id", "name"], name: "index_awarded_points_on_course_id_and_user_id_and_name", unique: true, using: :btree
  add_index "awarded_points", ["course_id", "user_id", "submission_id"], name: "index_awarded_points_on_course_id_and_user_id_and_submission_id", using: :btree
  add_index "awarded_points", ["user_id", "submission_id", "name"], name: "index_awarded_points_on_user_id_and_submission_id_and_name", unique: true, using: :btree

  create_table "certificates", force: true do |t|
    t.string   "name"
    t.binary   "pdf"
    t.integer  "user_id"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_notifications", force: true do |t|
    t.string   "topic"
    t.string   "message"
    t.integer  "sender_id"
    t.integer  "course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_templates", force: true do |t|
    t.string   "name"
    t.string   "title"
    t.string   "description"
    t.string   "material_url"
    t.string   "source_url"
    t.boolean  "dummy",          default: false,    null: false
    t.boolean  "hidden",         default: false
    t.integer  "cache_version",  default: 0,        null: false
    t.string   "source_backend", default: "git",    null: false
    t.string   "git_branch",     default: "master", null: false
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "courses", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "hide_after"
    t.boolean  "hidden",                         default: false, null: false
    t.integer  "cache_version",                  default: 0,     null: false
    t.string   "spreadsheet_key"
    t.datetime "hidden_if_registered_after"
    t.datetime "refreshed_at"
    t.boolean  "locked_exercise_points_visible", default: true,  null: false
    t.text     "description"
    t.string   "paste_visibility"
    t.string   "formal_name"
    t.boolean  "certificate_downloadable",       default: false, null: false
    t.string   "certificate_unlock_spec"
    t.integer  "organization_id"
    t.integer  "disabled_status",                default: 0
    t.string   "title"
    t.string   "material_url"
    t.integer  "course_template_id",                             null: false
  end

  add_index "courses", ["organization_id"], name: "index_courses_on_organization_id", using: :btree

  create_table "exercises", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.datetime "publish_time"
    t.string   "gdocs_sheet"
    t.boolean  "hidden",                           default: false, null: false
    t.boolean  "returnable_forced"
    t.string   "checksum",                         default: "",    null: false
    t.datetime "solution_visible_after"
    t.boolean  "has_tests",                        default: false, null: false
    t.text     "deadline_spec"
    t.text     "unlock_spec"
    t.string   "runtime_params",                   default: "[]",  null: false
    t.string   "valgrind_strategy"
    t.boolean  "code_review_requests_enabled",     default: false, null: false
    t.boolean  "run_tests_locally_action_enabled", default: true,  null: false
    t.text     "soft_deadline_spec"
    t.integer  "disabled_status",                  default: 0
  end

  add_index "exercises", ["course_id", "name"], name: "index_exercises_on_course_id_and_name", unique: true, using: :btree
  add_index "exercises", ["gdocs_sheet"], name: "index_exercises_on_gdocs_sheet", using: :btree

  create_table "feedback_answers", force: true do |t|
    t.integer  "feedback_question_id", null: false
    t.integer  "course_id",            null: false
    t.string   "exercise_name",        null: false
    t.integer  "submission_id"
    t.text     "answer",               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "feedback_answers", ["feedback_question_id", "course_id", "exercise_name"], name: "index_feedback_answers_question_course_exercise", using: :btree
  add_index "feedback_answers", ["submission_id"], name: "index_feedback_answers_question", using: :btree

  create_table "feedback_questions", force: true do |t|
    t.integer  "course_id",  null: false
    t.text     "question",   null: false
    t.string   "kind",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position",   null: false
    t.text     "title"
  end

  add_index "feedback_questions", ["id"], name: "index_feedback_questions_on_id", using: :btree

  create_table "organizations", force: true do |t|
    t.string   "name"
    t.string   "information"
    t.string   "slug"
    t.datetime "accepted_at"
    t.boolean  "acceptance_pending"
    t.boolean  "rejected",           default: false, null: false
    t.string   "rejected_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hidden",             default: false
    t.integer  "requester_id"
  end

  create_table "password_reset_keys", force: true do |t|
    t.integer  "user_id",    null: false
    t.text     "code",       null: false
    t.datetime "created_at", null: false
  end

  create_table "points_upload_queues", force: true do |t|
    t.integer  "point_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reply_to_feedback_answers", force: true do |t|
    t.integer  "feedback_answer_id"
    t.text     "body"
    t.string   "from"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reviews", force: true do |t|
    t.integer  "submission_id",                  null: false
    t.integer  "reviewer_id"
    t.text     "review_body",                    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "points"
    t.boolean  "marked_as_read", default: false, null: false
  end

  add_index "reviews", ["reviewer_id"], name: "index_reviews_on_reviewer_id", using: :btree
  add_index "reviews", ["submission_id"], name: "index_reviews_on_submission_id", using: :btree

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "submission_data", primary_key: "submission_id", force: true do |t|
    t.binary "return_file"
    t.binary "stdout_compressed"
    t.binary "stderr_compressed"
    t.binary "vm_log_compressed"
    t.binary "valgrind_compressed"
    t.binary "validations_compressed"
  end

  create_table "submissions", force: true do |t|
    t.integer  "user_id"
    t.text     "pretest_error"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "exercise_name",                                            null: false
    t.integer  "course_id",                                                null: false
    t.boolean  "processed",                                default: false, null: false
    t.string   "secret_token"
    t.boolean  "all_tests_passed",                         default: false, null: false
    t.text     "points"
    t.datetime "processing_tried_at"
    t.datetime "processing_began_at"
    t.datetime "processing_completed_at"
    t.integer  "times_sent_to_sandbox",                    default: 0,     null: false
    t.datetime "processing_attempts_started_at"
    t.integer  "processing_priority",                      default: 0,     null: false
    t.binary   "stdout_compressed"
    t.binary   "stderr_compressed"
    t.text     "params_json"
    t.boolean  "requires_review",                          default: false, null: false
    t.boolean  "requests_review",                          default: false, null: false
    t.boolean  "reviewed",                                 default: false, null: false
    t.text     "message_for_reviewer",                     default: "",    null: false
    t.boolean  "newer_submission_reviewed",                default: false, null: false
    t.boolean  "review_dismissed",                         default: false, null: false
    t.boolean  "paste_available",                          default: false, null: false
    t.text     "message_for_paste"
    t.string   "paste_key"
    t.datetime "client_time"
    t.integer  "client_nanotime",                limit: 8
    t.text     "client_ip"
  end

  add_index "submissions", ["course_id", "exercise_name"], name: "index_submissions_on_course_id_and_exercise_name", using: :btree
  add_index "submissions", ["course_id", "user_id"], name: "index_submissions_on_course_id_and_user_id", using: :btree
  add_index "submissions", ["processed"], name: "index_submissions_on_processed", using: :btree
  add_index "submissions", ["user_id", "exercise_name"], name: "index_submissions_on_user_id_and_exercise_name", using: :btree

  create_table "teacherships", force: true do |t|
    t.integer  "user_id"
    t.integer  "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "teacherships", ["user_id", "organization_id"], name: "index_teacherships_on_user_id_and_organization_id", unique: true, using: :btree

  create_table "test_case_runs", force: true do |t|
    t.integer  "submission_id"
    t.text     "test_case_name"
    t.text     "message"
    t.boolean  "successful"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "exception"
    t.text     "detailed_message"
  end

  add_index "test_case_runs", ["submission_id"], name: "index_test_case_runs_on_submission_id", using: :btree

  create_table "test_scanner_cache_entries", force: true do |t|
    t.integer  "course_id",     null: false
    t.string   "exercise_name"
    t.string   "files_hash"
    t.text     "value"
    t.datetime "created_at"
  end

  add_index "test_scanner_cache_entries", ["course_id", "exercise_name"], name: "index_test_scanner_cache_entries_on_course_id_and_exercise_name", unique: true, using: :btree

  create_table "uncomputed_unlocks", force: true do |t|
    t.integer  "course_id",  null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "uncomputed_unlocks", ["course_id", "user_id"], name: "index_uncomputed_unlocks_on_course_id_and_user_id", using: :btree

  create_table "unlocks", force: true do |t|
    t.integer  "user_id",       null: false
    t.integer  "course_id",     null: false
    t.string   "exercise_name", null: false
    t.datetime "valid_after"
    t.datetime "created_at",    null: false
  end

  add_index "unlocks", ["user_id", "course_id", "exercise_name"], name: "index_unlocks_on_user_id_and_course_id_and_exercise_name", unique: true, using: :btree

  create_table "user_field_values", force: true do |t|
    t.integer  "user_id",    null: false
    t.string   "field_name", null: false
    t.text     "value",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_field_values", ["user_id", "field_name"], name: "index_user_field_values_on_user_id_and_field_name", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.string   "login",                              null: false
    t.text     "password_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "salt"
    t.boolean  "administrator",      default: false, null: false
    t.text     "email",              default: "",    null: false
    t.boolean  "legitimate_student", default: true,  null: false
  end

  add_index "users", ["login"], name: "index_users_on_login", unique: true, using: :btree

  add_foreign_key "available_points", "exercises", :name => "available_points_exercise_id_fk", :dependent => :delete

  add_foreign_key "awarded_points", "courses", :name => "awarded_points_course_id_fk", :dependent => :delete
  add_foreign_key "awarded_points", "submissions", :name => "awarded_points_submission_id_fk", :dependent => :nullify
  add_foreign_key "awarded_points", "users", :name => "awarded_points_user_id_fk", :dependent => :delete

  add_foreign_key "exercises", "courses", :name => "exercises_course_id_fk", :dependent => :delete

  add_foreign_key "feedback_answers", "feedback_questions", :name => "feedback_answers_feedback_question_id_fk", :dependent => :delete
  add_foreign_key "feedback_answers", "submissions", :name => "feedback_answers_submission_id_fk", :dependent => :nullify

  add_foreign_key "feedback_questions", "courses", :name => "feedback_questions_course_id_fk", :dependent => :delete

  add_foreign_key "password_reset_keys", "users", :name => "password_reset_keys_user_id_fk", :dependent => :delete

  add_foreign_key "reviews", "submissions", :name => "reviews_submission_id_fk", :dependent => :delete
  add_foreign_key "reviews", "users", :name => "reviews_reviewer_id_fk", :column => "reviewer_id", :dependent => :nullify

  add_foreign_key "submission_data", "submissions", :name => "submission_data_submission_id_fk", :dependent => :delete

  add_foreign_key "submissions", "courses", :name => "submissions_course_id_fk", :dependent => :delete
  add_foreign_key "submissions", "users", :name => "submissions_user_id_fk", :dependent => :delete

  add_foreign_key "test_case_runs", "submissions", :name => "test_case_runs_submission_id_fk", :dependent => :delete

  add_foreign_key "test_scanner_cache_entries", "courses", :name => "test_scanner_cache_entries_course_id_fk", :dependent => :delete

  add_foreign_key "user_field_values", "users", :name => "user_field_values_user_id_fk", :dependent => :delete

end
