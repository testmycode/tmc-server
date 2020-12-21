class AddSecretTokenToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :secret_token, :string, null: true
  end
end
