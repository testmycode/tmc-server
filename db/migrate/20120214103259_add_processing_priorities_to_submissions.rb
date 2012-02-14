class AddProcessingPrioritiesToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :processing_priority, :integer, :null => false, :default => 0
  end
end
