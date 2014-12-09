class AddCourseRegistrations < ActiveRecord::Migration
  def change
    add_column :courses, :requires_registration, :boolean, null: false, default: false

    create_table :course_registrations do |t|
      t.integer :course_id, null: false
      t.integer :user_id, null: false
      t.timestamps
    end

    add_index :course_registrations, [:course_id, :user_id], unique: true
    add_foreign_key :course_registrations, :courses, dependent: :delete
    add_foreign_key :course_registrations, :users, dependent: :delete
  end
end
