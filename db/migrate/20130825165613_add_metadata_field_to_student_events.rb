class AddMetadataFieldToStudentEvents < ActiveRecord::Migration
  def change
    add_column :student_events, :metadata_json, :string, :null => true
  end
end
