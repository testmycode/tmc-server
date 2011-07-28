class CreatePoints < ActiveRecord::Migration
  def self.up
    create_table :points do |t|
      t.references :exercise
      t.string :name
    end
  end

  def self.down
    drop_table :points
  end
end
