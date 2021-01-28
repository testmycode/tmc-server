# frozen_string_literal: true

# Course stub to be copied by teachers for their own organisations

require 'net/http'

class CourseTemplate < ApplicationRecord
  include SystemCommands

  validates :name,
            presence: true,
            uniqueness: true,
            length: { within: 1..40 },
            format: {
              without: / /,
              message: 'should not contain white spaces'
            }
  validates :title,
            presence: true,
            length: { within: 1..255 }
  validates :description, length: { maximum: 512 }
  validates :git_branch, presence: true
  validates :source_url, presence: true
  validate :valid_git_repo?
  validate :valid_source_backend?

  after_initialize :set_default_source_backend

  has_many :courses
  has_many :course_template_refreshes

  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.now) }
  scope :not_hidden, -> { where(hidden: false) }
  scope :hidden, -> { where(hidden: true) }
  scope :not_dummy, -> { where(dummy: false) }
  scope :available, -> { not_expired.not_hidden.not_dummy }

  after_save :update_courses_sourcedata

  def self.new_dummy(course, options = {})
    CourseTemplate.new(dummy: true,
                       name: course.name,
                       title: course.title,
                       description: course.description,
                       material_url: course.material_url,
                       source_url: options[:source_url],
                       git_branch: options[:git_branch] || 'master',
                       source_backend: options[:source_backend] || 'git')
  end

  def valid_git_repo?
    result = sh!('git', 'ls-remote', '--exit-code', source_url, git_branch, timeout: 10)
    result[:status].success?
  rescue StandardError => e
    errors.add(:base, 'Cannot clone repository. Error: ' + e.to_s)
  end

  def valid_source_backend?
    errors.add(:source_backend, '"not git') unless source_backend == 'git'
  end

  def set_default_source_backend
    self.source_backend ||= CourseTemplate.default_source_backend
  end

  def self.default_source_backend
    'git'
  end

  def clonable?
    !hidden? && (expires_at.nil? || expires_at > Time.now) && !dummy?
  end

  def cache_path
    File.join(Course.cache_root, "#{name}-#{cached_version}")
  end

  def increment_cached_version
    self.cached_version += 1
    courses.each do |course|
      course.cached_version = cached_version
    end
  end

  def refresh(current_user_id)
    CourseTemplateRefresh.create!(user_id: current_user_id, course_template_id: self.id)
  end

  def cache_exists?
    File.exist?(cache_path)
  end

  private
    def update_courses_sourcedata
      courses.each do |c|
        c.cached_version = cached_version
        c.source_url = source_url
        c.git_branch = git_branch
        c.source_backend = source_backend
      end
    end
end
