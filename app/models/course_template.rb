# Course stub to be copied by teachers for their own organisations

require 'net/http'

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
  validate :valid_source_url?

  def valid_source_url?
    url = URI(source_url)
    Net::HTTP.get(url)
  rescue StandardError => e
    errors.add(:source_url, 'is invalid: ' + e.to_s)
  end
end
