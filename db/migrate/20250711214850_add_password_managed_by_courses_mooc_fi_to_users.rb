class AddPasswordManagedByCoursesMoocFiToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :password_managed_by_courses_mooc_fi, :boolean, default: false, null: false
  end
end
