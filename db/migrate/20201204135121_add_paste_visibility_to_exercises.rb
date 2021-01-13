class AddPasteVisibilityToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :paste_visibility, :integer, null: true
  end
end
