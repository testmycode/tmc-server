class AddGitBranchToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :git_branch, :text, :null => false, :default => 'master'
  end
end
