class AddCoursesMoocFiUserIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :courses_mooc_fi_user_id, :string
    add_index :users, :courses_mooc_fi_user_id, unique: true
  end
end
