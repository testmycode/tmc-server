#Course stub to be copied by teachers for their own organisations

class CourseTemplate < ActiveRecord::Base
  validates :name,
            presence: true,
            uniqueness: true,
            length: { within: 1..40 },
            format: {
              without: / /,
              message: 'should not contain white spaces'
            }
  validates :source_url, presence: true
  validates :title,
            presence: true,
            length: { within: 4..40 }
  validates :description, length: { maximum: 512 }
end
