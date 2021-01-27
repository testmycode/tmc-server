class CreateCourseTemplateRefreshPhases < ActiveRecord::Migration[4.2]
  def change
    create_table :course_template_refresh_phases do |t|
      t.string :phase_name, null: false
      t.integer :time_ms, null: false
      t.references :course_template_refresh, index: { name: 'index_course_refresh_phases_on_course_template_refresh_id'}, foreign_key: true, null: false
    end
  end
end
