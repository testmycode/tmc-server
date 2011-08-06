class RefactorPointsSomeMore < ActiveRecord::Migration
  def self.up
    drop_table "awarded_points"
    drop_table "points"
    
    create_table "awarded_points", :force => true do |t|
      t.integer "course_id", :null => false
      t.integer "user_id", :null => false
      t.integer "submission_id", :null => true
      t.string "name", :null => false
    end
    create_table "available_points" do |t|
      t.integer "exercise_id", :null => false
      t.string  "name", :null => false
    end
  end

  def self.down
    drop_table "awarded_points"
    drop_table "available_points"
    
    create_table "awarded_points", :force => true do |t|
      t.integer "user_id"
      t.integer "point_id"
    end
    create_table "points", :force => true do |t|
      t.integer "exercise_id"
      t.string  "name"
    end
  end
end
