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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120615225538) do

  create_table "available_points", :force => true do |t|
    t.integer "exercise_id", :null => false
    t.string  "name",        :null => false
  end

  create_table "awarded_points", :force => true do |t|
    t.integer "course_id",     :null => false
    t.integer "user_id",       :null => false
    t.integer "submission_id"
    t.string  "name",          :null => false
  end

  add_index "awarded_points", ["course_id", "user_id", "name"], :name => "index_awarded_points_on_course_id_and_user_id_and_name", :unique => true
  add_index "awarded_points", ["course_id", "user_id", "submission_id"], :name => "index_awarded_points_on_course_id_and_user_id_and_submission_id"
  add_index "awarded_points", ["user_id", "submission_id", "name"], :name => "index_awarded_points_on_user_id_and_submission_id_and_name", :unique => true

  create_table "courses", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "hide_after"
    t.boolean  "hidden",                     :default => false,    :null => false
    t.integer  "cache_version",              :default => 0,        :null => false
    t.string   "spreadsheet_key"
    t.string   "source_backend",                                   :null => false
    t.string   "source_url",                                       :null => false
    t.text     "git_branch",                 :default => "master", :null => false
    t.datetime "hidden_if_registered_after"
  end

  create_table "exercises", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.datetime "deadline"
    t.datetime "publish_time"
    t.string   "gdocs_sheet"
    t.boolean  "hidden",                 :default => false, :null => false
    t.boolean  "returnable_forced"
    t.string   "checksum",               :default => "",    :null => false
    t.datetime "solution_visible_after"
  end

  add_index "exercises", ["course_id", "name"], :name => "index_exercises_on_course_id_and_name"
  add_index "exercises", ["gdocs_sheet"], :name => "index_exercises_on_gdocs_sheet"

  create_table "feedback_answers", :force => true do |t|
    t.integer  "feedback_question_id", :null => false
    t.integer  "course_id",            :null => false
    t.string   "exercise_name",        :null => false
    t.integer  "submission_id"
    t.text     "answer",               :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "feedback_answers", ["feedback_question_id", "course_id", "exercise_name"], :name => "index_feedback_answers_question_course_exercise"
  add_index "feedback_answers", ["submission_id"], :name => "index_feedback_answers_question"

  create_table "feedback_questions", :force => true do |t|
    t.integer  "course_id",  :null => false
    t.text     "question",   :null => false
    t.string   "kind",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position",   :null => false
    t.text     "title"
  end

  create_table "password_reset_keys", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.text     "code",       :null => false
    t.datetime "created_at", :null => false
  end

  create_table "points_upload_queues", :force => true do |t|
    t.integer  "point_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "student_events", :force => true do |t|
    t.integer  "user_id",       :null => false
    t.integer  "course_id",     :null => false
    t.string   "exercise_name", :null => false
    t.string   "event_type",    :null => false
    t.binary   "data",          :null => false
    t.datetime "happened_at",   :null => false
  end

  add_index "student_events", ["user_id", "course_id", "exercise_name", "event_type", "happened_at"], :name => "index_student_events_user_course_exercise_type_time"
  add_index "student_events", ["user_id", "event_type", "happened_at"], :name => "index_student_events_user_type_time"

  create_table "submissions", :force => true do |t|
    t.integer  "user_id"
    t.binary   "return_file"
    t.text     "pretest_error"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "exercise_name",                                     :null => false
    t.integer  "course_id",                                         :null => false
    t.boolean  "processed",                      :default => false, :null => false
    t.string   "secret_token"
    t.boolean  "all_tests_passed",               :default => false, :null => false
    t.text     "points"
    t.datetime "processing_tried_at"
    t.datetime "processing_began_at"
    t.datetime "processing_completed_at"
    t.integer  "times_sent_to_sandbox",          :default => 0,     :null => false
    t.datetime "processing_attempts_started_at"
    t.integer  "processing_priority",            :default => 0,     :null => false
    t.binary   "stdout_compressed"
    t.binary   "stderr_compressed"
  end

  add_index "submissions", ["course_id", "exercise_name"], :name => "index_submissions_on_course_id_and_exercise_name"
  add_index "submissions", ["user_id", "exercise_name"], :name => "index_submissions_on_user_id_and_exercise_name"

  create_table "test_case_runs", :force => true do |t|
    t.integer  "submission_id"
    t.text     "test_case_name"
    t.text     "message"
    t.boolean  "successful"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "exception"
  end

  add_index "test_case_runs", ["submission_id"], :name => "index_test_case_runs_on_submission_id"

  create_table "test_scanner_cache_entries", :force => true do |t|
    t.integer  "course_id",     :null => false
    t.string   "exercise_name"
    t.string   "files_hash"
    t.text     "value"
    t.datetime "created_at"
  end

  add_index "test_scanner_cache_entries", ["course_id", "exercise_name"], :name => "index_test_scanner_cache_entries_on_course_id_and_exercise_name", :unique => true

  create_table "user_field_values", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "field_name", :null => false
    t.text     "value",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_field_values", ["user_id", "field_name"], :name => "index_user_field_values_on_user_id_and_field_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "login",                            :null => false
    t.text     "password_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "salt"
    t.boolean  "administrator", :default => false, :null => false
    t.text     "email",         :default => "",    :null => false
  end

  set_table_comment 'awarded_points', 'Stores points awarded to a user in a particular course. Each point is stored only once per user/course and each row refers to the first submission that awarded the point.'

  set_column_comment 'submissions', 'points', 'Space-separated list of points awarded. Filled each time unlike the awarded_points table, where a point is given at most once.'

end
