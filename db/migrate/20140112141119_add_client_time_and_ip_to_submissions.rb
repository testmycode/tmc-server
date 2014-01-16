class AddClientTimeAndIpToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :client_time, :timestamp, null: true
    add_column :submissions, :client_nanotime, :integer, limit: 8, null: true
    add_column :submissions, :client_ip, :text, null: true
  end
end
