class AddGdocsSheetToExercise < ActiveRecord::Migration
  def self.up
    add_column :exercises, :gdocs_sheet, :string
  end

  def self.down
    remove_column :exercises, :gdocs_sheet
  end
end
