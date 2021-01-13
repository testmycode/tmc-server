class AddPastePublicityFlagToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :paste_visibility, :string
  end
end
