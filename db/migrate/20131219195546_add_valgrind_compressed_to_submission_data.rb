class AddValgrindCompressedToSubmissionData < ActiveRecord::Migration
  def change
    add_column :submission_data, :valgrind_compressed, :binary, :null => true
  end
end
