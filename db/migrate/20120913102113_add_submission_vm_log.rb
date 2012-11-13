class AddSubmissionVmLog < ActiveRecord::Migration
  def change
    add_column :submission_data, :vm_log_compressed, :binary
  end
end
