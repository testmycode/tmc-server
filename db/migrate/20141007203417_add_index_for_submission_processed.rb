class AddIndexForSubmissionProcessed < ActiveRecord::Migration
  def change
    add_index :submissions, [:processed]
  end
end
