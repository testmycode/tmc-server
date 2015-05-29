class AddDisabledFlagToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :disabled, :boolean
  end
end
