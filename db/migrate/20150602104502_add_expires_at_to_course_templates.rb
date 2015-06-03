class AddExpiresAtToCourseTemplates < ActiveRecord::Migration
  def change
    add_column :course_templates, :expires_at, :datetime
  end
end
