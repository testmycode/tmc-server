class AddMultipleSourceBackendsToCourse < ActiveRecord::Migration[4.2]
  def up
    add_column :courses, :source_backend, :string
    add_column :courses, :source_url, :string
    execute "UPDATE courses SET source_backend = 'git', source_url = remote_repo_url"
    remove_column :courses, :remote_repo_url

    change_column :courses, :source_backend, :string, null: false
    change_column :courses, :source_url, :string, null: false
  end

  def down
    add_column :courses, :remote_repo_url, :string
    execute "UPDATE courses SET remote_repo_url = source_url"
    remove_column :courses, :source_backend
    remove_column :courses, :source_url
  end
end
