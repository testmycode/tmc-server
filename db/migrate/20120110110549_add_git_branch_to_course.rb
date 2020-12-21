class AddGitBranchToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :git_branch, :text, null: false, default: 'master'
  end
end
