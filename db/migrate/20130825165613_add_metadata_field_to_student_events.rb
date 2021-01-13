class AddMetadataFieldToStudentEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :student_events, :metadata_json, :string, null: true
  end
end
