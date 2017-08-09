class AddCreatedAtToAwardedPoint < ActiveRecord::Migration
  def change
    add_column(:awarded_points, :created_at, :datetime)
  end
end
