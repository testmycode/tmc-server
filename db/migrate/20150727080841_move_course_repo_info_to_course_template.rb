class MoveCourseRepoInfoToCourseTemplate < ActiveRecord::Migration

  class Course < ActiveRecord::Base
    belongs_to :course_template, :class_name => 'MoveCourseRepoInfoToCourseTemplate::CourseTemplate'
  end

  class CourseTemplate < ActiveRecord::Base
    has_many :courses, :class_name => 'MoveCourseRepoInfoToCourseTemplate::Course'
  end

  def up
    Course.reset_column_information
    CourseTemplate.reset_column_information
    Course.where(course_template_id: nil).each do |course|
      t = CourseTemplate.new(title: course.title,
                             name: course.name,
                             description: course.description,
                             source_url: course.source_url,
                             material_url: course.material_url,
                             git_branch: course.git_branch,
                             cache_version: course.cache_version,
                             dummy: true)
      t.save!
      course.update!(course_template_id: t.id)
    end

    remove_column :courses, :source_backend
    remove_column :courses, :source_url
    remove_column :courses, :git_branch
    change_column :courses, :course_template_id, :integer, null: false
  end

  def down
    add_column :courses, :source_backend, :string
    add_column :courses, :source_url, :string
    add_column :courses, :git_branch, :string, default: 'master'
    change_column :courses, :course_template_id, :integer, null: true

    # We shall unset the CourseTemplate from all courses, as otherwise soon
    # they would have no corresponding repo.
    CourseTemplate.each do |ct|
      ct.courses.each do |c|
        c.source_backend = ct.source_backend
        c.source_url = ct.source_url
        c.git_branch = ct.git_branch
        c.course_template_id = nil;
        c.save!(validate: false)
      end
      ct.destroy!
    end
  end
end
