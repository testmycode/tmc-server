class AddLateFlagToAwardedPoint < ActiveRecord::Migration
  def change
    add_column :awarded_points, :late, :boolean, default: false
  end
end
