class RefactorAwardedPoint < ActiveRecord::Migration
  def self.up
    drop_table :awarded_points
    create_table :awarded_points do |t|
      t.references :user
      t.references :point
    end
  end

  def self.down
    raise 'Irreversible'
  end
end
