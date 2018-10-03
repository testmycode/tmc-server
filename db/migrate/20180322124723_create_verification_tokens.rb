class CreateVerificationTokens < ActiveRecord::Migration[4.2]
  def change
    create_table :verification_tokens do |t|
      t.string :token, null: false
      t.integer :type, null: false
      t.references :user

      t.timestamps
    end
  end
end
