class CreateCourseRefreshPhaseTimings < ActiveRecord::Migration[4.2]
  def change
    create_table :course_refresh_phase_timings do |t|
      t.string :phase_name, null: false
      t.integer :time_ms, null: false
      t.references :course_refresh, index: true, foreign_key: true, null: false
    end
  end
end
