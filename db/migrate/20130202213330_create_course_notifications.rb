class CreateCourseNotifications < ActiveRecord::Migration
  def up
    create_table :course_notifications do |t|
      t.string :topic
      t.string :message
      t.references :user
      t.references :course

      t.timestamps
    end
  end

  def down
    drop_table :course_notifications
  end
end
