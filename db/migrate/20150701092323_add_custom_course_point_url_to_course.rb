class AddCustomCoursePointUrlToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :custom_points_url, :string
  end
end
