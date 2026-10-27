class AddTeachersCanCreateCustomCoursesToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :teachers_can_create_custom_courses, :boolean, default: false, null: false
  end
end
