class AddSourceInformationToCourseTemplates < ActiveRecord::Migration
  def change
    add_column :course_templates, :source_backend, :string, null: false, default: 'git'
    add_column :course_templates, :git_branch, :text, null: false, default: 'master'
  end
end
