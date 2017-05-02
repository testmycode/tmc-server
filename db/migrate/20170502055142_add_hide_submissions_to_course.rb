class AddHideSubmissionsToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :hide_submissions, :boolean, null: false, default: false
  end
end
