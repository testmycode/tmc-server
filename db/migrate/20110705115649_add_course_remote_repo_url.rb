class AddCourseRemoteRepoUrl < ActiveRecord::Migration
  def self.up
    add_column :courses, :remote_repo_url, :string, :null => true
  end

  def self.down
    remove_column :courses, :remote_repo_url
  end
end
