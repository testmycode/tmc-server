class AddCourseTemplateIdToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :course_template_id, :integer
  end
end
