class AddMoocfiIdToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :moocfi_id, :string
  end
end
