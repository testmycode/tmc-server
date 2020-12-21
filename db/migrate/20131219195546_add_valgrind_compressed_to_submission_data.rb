class AddValgrindCompressedToSubmissionData < ActiveRecord::Migration[4.2]
  def change
    add_column :submission_data, :valgrind_compressed, :binary, null: true
  end
end
