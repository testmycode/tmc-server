class CommentAwardedPointsColumnAndTable < ActiveRecord::Migration
  def up
    set_table_comment :awarded_points, 'Stores points awarded to a user in a particular course. Each point is stored only once per user/course and each row refers to the first submission that awarded the point.'
    set_column_comment :submissions, :points, 'Space-separated list of points awarded. Filled each time unlike the awarded_points table, where a point is given at most once.'
  end

  def down
    remove_table_comment :awarded_points
    remove_column_comment :submissions, :points
  end
end
