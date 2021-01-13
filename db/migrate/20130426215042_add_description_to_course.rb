class AddDescriptionToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :description, :text
  end
end
