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

ActiveRecord::Schema.define(:version => 20110717095945) do

  create_table "courses", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "hide_after"
    t.string   "remote_repo_url"
  end

  create_table "exercises", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.datetime "deadline"
    t.datetime "publish_date"
    t.string   "gdocs_sheet"
  end

  create_table "points_upload_queues", :force => true do |t|
    t.integer  "point_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "submissions", :force => true do |t|
    t.integer  "exercise_id"
    t.binary   "return_file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "student_id"
    t.text     "pretest_error"
  end

  create_table "test_case_runs", :force => true do |t|
    t.string   "exercise"
    t.string   "class_name"
    t.string   "method_name"
    t.string   "message"
    t.boolean  "success"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submission_id"
  end

  create_table "users", :force => true do |t|
    t.string   "login",         :null => false
    t.string   "password_hash", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "salt"
  end

end
