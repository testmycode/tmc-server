class AddHiddenIfRegisteredAfterToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :hidden_if_registered_after, :datetime, null: true
  end
end
