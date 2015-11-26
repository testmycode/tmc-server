class StoreUsedSandboxInSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :sandbox, :string
  end
end
