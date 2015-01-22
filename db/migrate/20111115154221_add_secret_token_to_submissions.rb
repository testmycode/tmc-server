class AddSecretTokenToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :secret_token, :string, null: true
  end
end
