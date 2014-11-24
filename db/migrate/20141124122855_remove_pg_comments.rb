class RemovePgComments < ActiveRecord::Migration
  def change
    remove_table_comment :awarded_points
    remove_column_comments :reviews, :points
    remove_column_comments :submissions, :points
  end
end
