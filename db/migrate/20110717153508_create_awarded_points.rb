class CreateAwardedPoints < ActiveRecord::Migration
  def self.up
    create_table :awarded_points do |t|
      t.references :course, :null => false
      t.references :user, :null => false
      t.text :name, :null => false
    end
    
    add_index(:awarded_points, [:course_id, :user_id, :name], :unique => true)
  end

  def self.down
    drop_table :awarded_points
  end
end
