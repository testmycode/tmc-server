class AddRepliedColumnToFeedbackAnswer < ActiveRecord::Migration
  def change
    add_column :feedback_answers, :replied, :boolean, :default => false
  end
end