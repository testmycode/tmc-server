class RemoveOldCourseHiddenFields < ActiveRecord::Migration
  def up
    rename_column :courses, :disabled_status, :status

    Course.all.each do |course|
      course.update!(status: 2) if course.hidden
      unless course.hide_after.nil?
        if course.hide_after <= Time.now
          course.update!(status: 2)
        else
          course.update!(enrollment_ends_at: course.hide_after)
        end
      end
      course.update!(enrollment_ends_at: course.hidden_if_registered_after) unless course.hidden_if_registered_after.nil?
    end

    remove_column :courses, :hidden
    remove_column :courses, :hide_after
    remove_column :courses, :hidden_if_registered_after
  end

  def down
    add_column :courses, :hidden, :boolean, default: false, null: false
    add_column :courses, :hide_after, :datetime
    add_column :courses, :hidden_if_registered_after, :datetime
    rename_column :courses, :status, :disabled_status

    Course.all.each do |course|
      course.update!(hidden: true, disabled_status: 0) if course.disabled_status == 2
      course.update!(hidden_if_registered_after: course.enrollment_ends_at)
    end
  end
end
