class CreateCourseTemplateRefreshReport < ActiveRecord::Migration[6.1]
  def change
    create_table :course_template_refresh_reports do |t|

      t.text :refresh_errors
      t.text :refresh_warnings
      t.text :refresh_notices
      t.text :refresh_timings
      t.references :course_template_refresh, index: { name: 'index_course_refresh_reports_on_course_template_refresh_id'}, foreign_key: true, null: false
    end
  end
end
