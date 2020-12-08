class AddPasteVisibilityToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :paste_visibility, :integer, null: true
  end
end
