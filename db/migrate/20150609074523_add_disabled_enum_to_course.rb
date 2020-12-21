class AddDisabledEnumToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :disabled_status, :integer, default: 0
  end
end
