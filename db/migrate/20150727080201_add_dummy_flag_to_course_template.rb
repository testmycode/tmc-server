class AddDummyFlagToCourseTemplate < ActiveRecord::Migration
  def change
    add_column :course_templates, :dummy, :boolean, null: false, default: false
  end
end
