class AddAwardedPointListToSubmission < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :points, :text, null: true
  end
end
