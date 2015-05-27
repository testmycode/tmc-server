class CourseBelongsToOrganization < ActiveRecord::Migration
  def change
    add_reference :courses, :organization, index: true, foreign_key: true
  end
end
