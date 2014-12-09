class AddAwardedPointListToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :points, :text, null: true
  end
end
