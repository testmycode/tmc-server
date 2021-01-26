class CreateCourseRefreshReport < ActiveRecord::Migration[6.1]
  def change
    create_table :course_refresh_reports do |t|

      t.text :refresh_errors
      t.text :refresh_warnings
      t.text :refresh_notices
      t.text :refresh_timings
      t.references :course_refresh, index: true, foreign_key: true, null: false
    end
  end
end
