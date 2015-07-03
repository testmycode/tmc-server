class AddHideSubmissionResultToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :hide_submission_result, :boolean, default: false
  end
end
