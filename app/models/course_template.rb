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
    FileUtils.rm_rf(clone_validation_path)
    FileUtils.mkdir_p(clone_validation_path)
    sh!('git', 'clone', '-q', '-b', 'master', self.source_url, clone_validation_path)
    if File.exist?("#{clone_validation_path}/.git")
      FileUtils.rm_rf(clone_validation_path)
      return true
    end
    FileUtils.rm_rf(clone_validation_path)
    errors.add(:source_url, 'is invalid: Could not clone git repo')
  rescue StandardError => e
    FileUtils.rm_rf(clone_validation_path)
    errors.add(:source_url, 'is invalid: ' + e.to_s)
  end

  def clone_validation_path
    "#{FileStore.root}/validation"
  end
end
