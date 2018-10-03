class StoreUsedSandboxInSubmission < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :sandbox, :string
  end
end
