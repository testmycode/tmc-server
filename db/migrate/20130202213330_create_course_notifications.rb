class CreateCourseNotifications < ActiveRecord::Migration[4.2]
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
