class CreateCourseTemplates < ActiveRecord::Migration
  def change
    create_table :course_templates do |t|
      t.string :name, unique: true
      t.string :title
      t.string :description
      t.string :material_url
      t.string :source_url
      t.integer  "cache_version",   default: 0,     null: false

      t.timestamps
    end
  end
end
