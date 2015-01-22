class AddValidationsCompressedToSubmissionData < ActiveRecord::Migration
  def change
    add_column :submission_data, :validations_compressed, :binary, null: true
  end
end
