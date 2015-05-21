class MakeOrganizationNameAndSlugUnique < ActiveRecord::Migration
  def change
    add_index :organizations, :name, unique: true
    add_index :organizations, :slug, unique: true
  end
end
