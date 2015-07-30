class MoveCourseRepoInfoToCourseTemplate < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        Course.where(course_template_id: nil).each do |course|
          t = CourseTemplate.new(title: course.title,
                                 name: course.organization.slug + '-' + course.name,
                                 description: course.description,
                                 source_url: course.source_url,
                                 material_url: course.material_url,
                                 git_branch: course.git_branch,
                                 cache_version: course.cache_version,
                                 dummy: true)
          t.save!(validate: false)
          course.update!(course_template: t)
        end

        change_column_null :courses, :course_template_id, false
        remove_column :courses, :source_backend
        remove_column :courses, :source_url
        remove_column :courses, :git_branch
      end

      dir.down do
        raise ActiveRecord::IrreversibleMigration, 'Cannot reverse'
      end
    end
  end
end
