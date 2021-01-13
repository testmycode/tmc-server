class AddIndexForSubmissionProcessed < ActiveRecord::Migration[4.2]
  def change
    add_index :submissions, [:processed]
  end
end
