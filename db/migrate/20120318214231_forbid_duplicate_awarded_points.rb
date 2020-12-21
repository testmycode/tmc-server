class ForbidDuplicateAwardedPoints < ActiveRecord::Migration[4.2]
  def up
    execute <<EOS
DELETE FROM awarded_points
WHERE id NOT IN (
  SELECT MIN(id)
  FROM awarded_points
  GROUP BY course_id, user_id, name
)
EOS
    add_index :awarded_points, [:course_id, :user_id, :name], unique: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
