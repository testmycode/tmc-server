class AddPasteBublicityFlagToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :paste_visibility, :string
  end
end
