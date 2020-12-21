class AddMessageForReviewerToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :message_for_reviewer, :text, null: false, default: ''
  end
end
