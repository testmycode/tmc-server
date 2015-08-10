class CreateCourseTemplates < ActiveRecord::Migration
  def change
    create_table :course_templates do |t|
      t.string :name, unique: true
      t.string :title
      t.string :description
      t.string :material_url
      t.string :source_url
      t.boolean :dummy, null: false, default: false
      t.boolean :hidden, default: false
      t.integer :cache_version,   default: 0,     null: false
      t.string :source_backend, null: false, default: 'git'
      t.string :git_branch, null: false, default: 'master'
      t.datetime :expires_at

      t.timestamps
    end
    add_reference :courses, :course_template
  end
end
