class AddSpreadsheetKeyToCourse < ActiveRecord::Migration
  def self.up
    add_column :courses, :spreadsheet_key, :string, :default => nil
  end

  def self.down
    remove_column :courses, :spreadsheet_key
  end
end
