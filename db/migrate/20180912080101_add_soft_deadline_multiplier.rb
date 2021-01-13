class AddSoftDeadlineMultiplier < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :soft_deadline_point_multiplier, :float, null: false, default: 0.75
    add_column :awarded_points, :awarded_after_soft_deadline, :boolean, null: false, default: false
  end
end
