require 'zlib'
require 'securerandom'

class Submission < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :exercise, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "exercises.course_id = #{self.course_id}" } # TODO: self.course_id not available when doing includes(:exercise))

  has_one :submission_data, :dependent => :delete
  after_save { submission_data.save! if submission_data }

  has_many :test_case_runs, :dependent => :delete_all, :order => :id
  has_many :reviews, :dependent => :delete_all, :order => :created_at do
    def latest
      self.order('created_at DESC').limit(1).first
    end
  end
  has_many :awarded_points, :dependent => :nullify
  has_many :feedback_answers, :dependent => :nullify

  validates :user, :presence => true
  validates :course, :presence => true
  validates :exercise_name, :presence => true
  before_create :set_processing_attempts_started_at
  before_create :set_paste_key_if_paste_available

  acts_as_api
  api_accessible :submission_show do |t|
    t.add :exercise_name
    t.add :id
    t.add :course_id
    t.add :created_at
    t.add :all_tests_passed
    t.add :points
    t.add :submitted_zip_url
    t.add :paste_url
    t.add :processing_time
    t.add :reviewed?
    t.add :requests_review?
  end

  def submitted_zip_url
    Rails.application.routes.url_helpers.submission_url(self.id, format: 'zip')
  end

  def paste_url
    if self.paste_key
      Rails.application.routes.url_helpers.paste_url(self.paste_key)
    else
      nil
    end
  end

  def processing_time
    if self.processing_completed_at.nil? or self.processing_completed_at.nil?
      nil
    else
      (self.processing_completed_at - self.processing_attempts_started_at).round
    end
  end

  def self.to_be_reprocessed
    self.unprocessed.
      where('processing_tried_at IS NULL OR processing_tried_at < ?', Time.now - processing_retry_interval).
      where('processing_began_at IS NULL OR processing_began_at < ?', Time.now - processing_resend_interval)
  end

  def self.unprocessed
    self.where(:processed => false).
      order('processing_priority DESC, processing_tried_at ASC, id ASC')
  end

  def self.unprocessed_count
    self.unprocessed.count
  end

  # How many times at most should a submission be (successfully) sent to a sandbox
  def self.max_attempts_at_processing
    3
  end

  before_create :randomize_secret_token

  def tests_ran?
    processed? && pretest_error == nil
  end

  def result_url
    "#{SiteSetting.value(:baseurl_for_remote_sandboxes).sub(/\/+$/, '')}/submissions/#{self.id}/result"
  end

  def params
    if self.params_json
      ActiveSupport::JSON.decode(self.params_json)
    else
      nil
    end
  end

  def params=(value)
    if value.is_a?(Hash)
      value.each {|k, v| raise "Invalid submission param: #{k} = #{v}" if !valid_param?(k, v) }
      self.params_json = value.to_json
    elsif value == nil
      self.params_json = nil
    else
      raise "Invalid submission params: #{value.inspect}"
    end
  end

  def valid_param?(k, v)
    # See also: SubmissionPackager.write_extra_params
    k = k.to_s
    v = v.to_s
    k =~ /^[a-zA-Z\-_]+$/ && v =~ /^[a-zA-Z\-_]+$/
  end

  def status
    if !processed?
      :processing
    elsif all_tests_passed?
      :ok
    elsif tests_ran?
      :fail
    else
      :error
    end
  end

  def points_list
    points.to_s.split(' ')
  end

  # Returns a query for all submissions (including this one) by the same user
  # for the same course and exercise
  def of_same_kind
    Submission.where(
      :course_id => self.course_id,
      :exercise_name => self.exercise_name,
      :user_id => self.user_id
    )
  end

  # Returns the newest submission by the same user for the same exercise,
  # as long as it's newer than this submission
  def newest_of_same_kind
    of_same_kind.where(['created_at > ?', self.created_at]).order('created_at DESC').first
  end

  def review_dismissable?
    (requires_review? || requests_review?) &&
      !review_dismissed? &&
      !newer_submission_reviewed?
  end

  def unprocessed_submissions_before_this
    if !self.processed?
      i = 0
      self.class.unprocessed.select(:id).each do |s|
        return i if s.id == self.id
        i += 1
      end
      0 # race condition
    else
      0
    end
  end

  def downloadable_file_name
    "#{exercise_name}-#{self.id}.zip"
  end

  def test_case_records
    test_case_runs.map do |tcr|
      {
        :name => tcr.test_case_name,
        :successful => tcr.successful?,
        :message => tcr.message,
        :exception => if tcr.exception then ActiveSupport::JSON.decode(tcr.exception) else nil end,
        :detailed_message => if tcr.detailed_message then tcr.detailed_message else nil end
      }
    end
  end

  def return_file
    submission_data.return_file
  end
  def return_file=(value)
    build_submission_data if !submission_data
    submission_data.return_file = value
  end

  def stdout
    build_submission_data if !submission_data
    submission_data.stdout
  end
  def stdout=(value)
    build_submission_data if !submission_data
    submission_data.stdout = value
  end
  def stderr
    build_submission_data if !submission_data
    submission_data.stderr
  end
  def stderr=(value)
    build_submission_data if !submission_data
    submission_data.stderr = value
  end
  def vm_log
    build_submission_data if !submission_data
    submission_data.vm_log
  end
  def vm_log=(value)
    build_submission_data if !submission_data
    submission_data.vm_log = value
  end
  def valgrind
    build_submission_data if !submission_data
    submission_data.valgrind
  end
  def valgrind=(value)
    build_submission_data if !submission_data
    submission_data.valgrind = value
  end


  def raise_pretest_error_if_any
    if pretest_error != nil
      error = "Submission failed: #{pretest_error}."
      if stdout.blank?
        error << "\n\n(no stdout)"
      else
        error << "\n\nStdout:\n#{stdout}"
      end
      if stderr.blank?
        error << "\n\n(no stderr)"
      else
        error << "\n\nStderr:\n#{stderr}"
      end
      raise error
    end
  end

  def set_to_be_reprocessed!(priority = -1)
    self.processed = false
    self.times_sent_to_sandbox = 0
    self.processing_priority = priority
    self.processing_attempts_started_at = Time.now
    self.processing_tried_at = nil
    self.processing_began_at = nil
    self.processing_completed_at = nil
    self.randomize_secret_token
    self.save!
  end

  # When a remote sandbox returns a result to the webapp,
  # it authenticates the result by passing back the secret token.
  # Changing it in the meantime will obsolete any runs currently being processed.
  def randomize_secret_token
    self.secret_token = rand(10**100).to_s
  end

  # How often we try to resend if no sandbox has received it yet
  def self.processing_retry_interval
    7.seconds
  end

  # How often we try to resend after a sandbox has received but not responded with a result
  def self.processing_resend_interval
    5.minutes
  end

  # A dirty workaround. See http://stackoverflow.com/questions/10666808/rails-eager-loading-a-belongs-to-with-conditions-refering-to-self
  def self.eager_load_exercises(submissions)
    keys = submissions.map {|s| "(#{connection.quote(s.course_id)}, #{connection.quote(s.exercise_name)})" }
    keys.uniq!
    return if keys.empty?

    exercises = Exercise.where('(course_id, name) IN (' + keys.join(',') + ')')
    by_key = Hash[exercises.map {|e| [[e.course_id, e.name], e] }]
    for sub in submissions
      ex = by_key[[sub.course_id, sub.exercise_name]]
      sub.exercise = ex
    end
  end

  def public?
    self.paste_available and not self.all_tests_passed
  end


  def set_paste_key_if_paste_available
    if self.paste_available?
      self.paste_key = SecureRandom.urlsafe_base64
    end
  end

private
  def set_processing_attempts_started_at
    self.processing_attempts_started_at = Time.now
  end


end
