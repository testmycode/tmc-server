# Course stub to be copied by teachers for their own organisations

require 'net/http'
require 'course_refresher'

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

  has_many :courses

  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.now) }
  scope :not_hidden, -> { where(hidden: false) }
  scope :available, -> { not_expired.not_hidden }

  def valid_source_url?
    return true unless source_url_changed? # don't attempt repo cloning if source url wasn't even changed
    Dir.mktmpdir do |dir|
      sh!('git', 'clone', '-q', '-b', 'master', source_url, dir)
      File.exist?("#{dir}/.git")
    end
  rescue StandardError => e
    errors.add(:source_url, 'is invalid: ' + e.to_s)
  end

  def clonable?
    !hidden && (expires_at.nil? || expires_at > Time.now)
  end

  def cache_path
    "#{Course.cache_root}/#{name}-#{cache_version}"
  end

  def refresh
    firstcourse = true
    courses.each do |c|
      options = firstcourse ? {} : {no_directory_changes: true}
      CourseRefresher.new.refresh_course(c, options)
      firstcourse = false
    end
  end
end
