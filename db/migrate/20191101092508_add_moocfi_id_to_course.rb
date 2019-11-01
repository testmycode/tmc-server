class AddMoocfiIdToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :moocfi_id, :string
  end
end
