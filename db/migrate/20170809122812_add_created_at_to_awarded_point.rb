class AddCreatedAtToAwardedPoint < ActiveRecord::Migration
  def change
    add_column :awarded_points, :created_at, :datetime
    AwardedPoint.all.each do |awarded_point|
      awarded_point.update_attributes! :created_at => awarded_point.submission.created_at
    end
  end
end
