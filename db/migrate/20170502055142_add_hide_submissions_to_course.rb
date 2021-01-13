class AddHideSubmissionsToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :hide_submissions, :boolean, null: false, default: false
  end
end
