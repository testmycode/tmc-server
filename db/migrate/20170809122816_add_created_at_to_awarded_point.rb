class AddCreatedAtToAwardedPoint < ActiveRecord::Migration[4.2]
  def change
    add_column :awarded_points, :created_at, :datetime
    AwardedPoint.find_each do |awarded_point|
      awarded_point.update!(created_at: awarded_point.submission.created_at) if awarded_point.submission
    end
  end
end
