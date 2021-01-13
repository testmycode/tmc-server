class AddTitleAndMaterialUrlToCourses < ActiveRecord::Migration[4.2]

  class Course < ActiveRecord::Base
  end

  def change
    add_column :courses, :title, :string
    add_column :courses, :material_url, :string

    reversible do |dir|
      dir.up do
        Course.all.each { |c| c.title = c.name.titleize; c.save! }
      end
    end
  end
end
