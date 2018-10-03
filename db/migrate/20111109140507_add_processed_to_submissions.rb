class AddProcessedToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :processed, :boolean, null: false, default: false
  end
end
