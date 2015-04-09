class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates do |t|
      t.string :name
      t.integer :user_id
      t.integer :course_id

      t.timestamps
    end
  end
end
