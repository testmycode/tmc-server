class AddBannedEmails < ActiveRecord::Migration[6.1]
  def change
    create_table :banned_emails do |t|
      t.string :email, null: false
      t.timestamps
    end
  end
end
