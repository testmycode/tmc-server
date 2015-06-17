class AddTitleAndMaterialUrlToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :title, :string
    add_column :courses, :material_url, :string
    reversible do |dir|
      dir.up do
        Course.all.each { |c| c.title = c.name; c.save! }
      end
    end
  end
end
