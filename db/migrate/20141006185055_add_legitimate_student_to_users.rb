class AddLegitimateStudentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :legitimate_student, :boolean, null: false, default: true
  end
end
