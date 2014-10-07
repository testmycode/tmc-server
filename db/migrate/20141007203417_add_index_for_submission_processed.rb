class AddIndexForSubmissionProcessed < ActiveRecord::Migration
  def up
    add_index :submissions, [:processed]
  end
end
