class CreateCourseTemplateRefreshes < ActiveRecord::Migration[4.2]
  def change
    create_table :course_template_refreshes do |t|
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :status, null: false, default: 0 # (enum: [:not_started, :in_progress, :complete , :crashed] https://api.rubyonrails.org/v5.2.4.4/classes/ActiveRecord/Enum.html)
      t.decimal :percent_done, null: false, default: 0, scale: 4, precision: 10
      t.jsonb :langs_refresh_output # use json or jsonb?
      t.references :user, index: true, foreign_key: true, null: false
      t.references :course_template, index: true, foreign_key: true, null: false
    end
  end
end
