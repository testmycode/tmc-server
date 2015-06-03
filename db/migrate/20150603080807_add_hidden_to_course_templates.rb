class AddHiddenToCourseTemplates < ActiveRecord::Migration
  def change
    add_column :course_templates, :hidden, :boolean, default: false
  end
end
