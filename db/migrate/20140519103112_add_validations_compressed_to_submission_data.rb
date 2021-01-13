class AddValidationsCompressedToSubmissionData < ActiveRecord::Migration[4.2]
  def change
    add_column :submission_data, :validations_compressed, :binary, null: true
  end
end
