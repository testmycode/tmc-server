class AddSubmissionVmLog < ActiveRecord::Migration[4.2]
  def change
    add_column :submission_data, :vm_log_compressed, :binary
  end
end
