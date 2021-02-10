class AddConfidentialToOauthApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :oauth_applications, :confidential, :boolean, default: true, null: false
  end
end
