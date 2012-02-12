class AddHiddenIfRegisteredAfterToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :hidden_if_registered_after, :datetime, :null => true
  end
end
