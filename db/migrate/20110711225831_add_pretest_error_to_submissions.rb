class AddPretestErrorToSubmissions < ActiveRecord::Migration
  def self.up
    add_column :submissions, :pretest_error, :text, :null => true
  end

  def self.down
    remove_column :submissions, :pretest_error
  end
end
