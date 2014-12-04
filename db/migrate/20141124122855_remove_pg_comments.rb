class RemovePgComments < ActiveRecord::Migration
  def change
    if respond_to?(:remove_table_comment)
      remove_table_comment :awarded_points
      remove_column_comments :reviews, :points
      remove_column_comments :submissions, :points
    end
  end
end
