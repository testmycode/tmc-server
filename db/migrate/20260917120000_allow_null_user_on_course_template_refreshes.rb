class AllowNullUserOnCourseTemplateRefreshes < ActiveRecord::Migration[7.1]
  def up
    change_column_null :course_template_refreshes, :user_id, true
    remove_foreign_key :course_template_refreshes, :users
    add_foreign_key :course_template_refreshes, :users, on_delete: :nullify
  end

  def down
    remove_foreign_key :course_template_refreshes, :users
    change_column_null :course_template_refreshes, :user_id, false
    add_foreign_key :course_template_refreshes, :users
  end
end
