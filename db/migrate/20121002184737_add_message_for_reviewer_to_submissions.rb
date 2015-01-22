class AddMessageForReviewerToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :message_for_reviewer, :text, null: false, default: ''
  end
end
