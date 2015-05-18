class CreateCourseTemplates < ActiveRecord::Migration
  def change
    create_table :course_templates do |t|
      t.string :name
      t.string :title
      t.string :description
      t.string :material_url
      t.string :source_url

      t.timestamps
    end
  end
end
