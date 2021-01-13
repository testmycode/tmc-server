class RenamePasswordResetKeyToActionToken < ActiveRecord::Migration[4.2]

  class ActionToken < ActiveRecord::Base

  end

  def up
    rename_table :password_reset_keys, :action_tokens
    rename_column :action_tokens, :code, :token
    add_column :action_tokens, :action, :integer, null: true
    add_column :action_tokens, :expires_at, :datetime
    add_column :action_tokens, :updated_at, :datetime

    ActionToken.all.each do |at|
      at.update!(action: 1, expires_at: at.created_at + 24.hours)
      raise MigrationError('Action token (id: '+at.id+') has more than 255 characters.') if at.token.length > 255
    end

    change_column_null :action_tokens, :action, false

    change_column :action_tokens, :token, :string
  end

  def down
    remove_column :action_tokens, :updated_at
    remove_column :action_tokens, :expires_at

    ActionToken.all.each do |at|
      at.destroy! if at.action != 1
    end

    remove_column :action_tokens, :action
    change_column :action_tokens, :token, :text, limit: 255
    rename_column :action_tokens, :token, :code
    rename_table :action_tokens, :password_reset_keys
  end
end
