class AddProcessingPrioritiesToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :processing_priority, :integer, null: false, default: 0
  end
end
