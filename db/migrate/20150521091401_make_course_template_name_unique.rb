class MakeCourseTemplateNameUnique < ActiveRecord::Migration
  def change
    add_index :course_templates, :name, unique: true
  end
end
