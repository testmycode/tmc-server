class AddMoreTimestampsToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :processing_tried_at, :datetime, :null => true
    add_column :submissions, :processing_began_at, :datetime, :null => true
    add_column :submissions, :processing_completed_at, :datetime, :null => true
  end
end
