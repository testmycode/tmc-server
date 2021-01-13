class AddLegitimateStudentToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :legitimate_student, :boolean, null: false, default: true

    User.where(administrator: true).update_all(legitimate_student: false)
  end

  def down
    remove_column :users, :legitimate_student
  end
end
