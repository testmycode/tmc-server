class AddProcessedToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :processed, :boolean, null: false, default: false
  end
end
