# Course stub to be copied by teachers for their own organisations

require 'net/http'

class CourseTemplate < ActiveRecord::Base
  include SystemCommands

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
    return true unless source_url_changed? # don't attempt repo cloning if source url wasn't even changed
    Dir.mktmpdir do |dir|
      sh!('git', 'clone', '-q', '-b', 'master', self.source_url, dir)
      File.exist?("#{dir}/.git")
    end
  rescue StandardError => e
    errors.add(:source_url, 'is invalid: ' + e.to_s)
  end
end
