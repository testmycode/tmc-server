class AddPasteOptionsToSubmission < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :paste_available, :boolean, null: false, default: false
    add_column :submissions, :message_for_paste, :text
  end
end
