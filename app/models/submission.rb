# frozen_string_literal: true

require 'zlib'
require 'securerandom'

class Submission < ApplicationRecord
  include Swagger::Blocks

  swagger_schema :Submission do
    key :required, %i[id user_id pretest_error created_at exercise_name course_id processed
                      all_tests_passed points processing_tried_at processing_began_at processing_completed_at
                      times_sent_to_sandbox processing_attempts_started_at params_json requires_review
                      requests_review reviewed message_for_reviewer newer_submission_reviewed review_dismissed
                      paste_available message_for_paste paste_key]

    property :id, type: :integer, example: 1
    property :user_id, type: :integer, example: 1
    property :pretest_error, type: :string, description: 'Can be null', example: 'Missing test output. Did you terminate your program with an exit() command?'
    property :created_at, type: :string, example: '2016-10-17T11:10:17.295+03:00'
    property :exercise_name, type: :string, example: 'trivial'
    property :course_id, type: :integer, example: 1
    property :processed, type: :boolean, example: true
    property :all_tests_passed, type: :boolean, example: true
    property :points, type: :string, description: 'Can be null'
    property :processing_tried_at, type: :string, example: '2016-10-17T11:10:17.295+03:00'
    property :processing_began_at, type: :string, example: '2016-10-17T11:10:17.295+03:00'
    property :processing_completed_at, type: :string, example: '2016-10-17T11:10:17.295+03:00'
    property :times_sent_to_sandbox, type: :integer, example: 1
    property :processing_attempts_started_at, type: :string, example: '2016-10-17T11:10:17.295+03:00'
    property :params_json, type: :string, example: '{"error_msg_locale":"en"}'
    property :requires_review, type: :boolean, example: true
    property :requests_review, type: :boolean, example: true
    property :reviewed, type: :boolean, example: true
    property :message_for_reviewer, type: :string, example: ''
    property :newer_submission_reviewed, type: :boolean, example: true
    property :review_dismissed, type: :boolean, example: true
    property :paste_available, type: :boolean, example: true
    property :message_for_paste, type: :string, example: ''
    property :paste_key, type: :string, description: 'Can be null'
  end

  swagger_schema :CoreSubmission do
    key :required, %i[exercise_name id user_id course_id created_at all_tests_passed points
                      submitted_zip_url paste_url processing_time reviewed requests_review]

    property :exercise_name, type: :string, example: 'exercise'
    property :id, type: :integer, example: 1
    property :user_id, type: :integer, example: 1
    property :course_id, type: :integer, example: 1
    property :created_at, type: :string, format: 'date-time', example: '2016-12-05T12:00:00.000+03:00'
    property :all_tests_passed, type: :boolean, example: true
    property :points, type: :string, example: 'point1'
    property :submitted_zip_url, type: :string, example: 'http://example.com/api/v8/core/submissions/1/download'
    property :paste_url, type: :string, example: 'http://example.com/paste/qqbKk2Z7INqBH8cmaZ7i_A,'
    property :processing_time, type: :integer, example: 25
    property :reviewed, type: :boolean, example: false
    property :requests_review, type: :boolean, example: false
  end

  belongs_to :user
  belongs_to :course, counter_cache: true

  belongs_to :exercise,
             (lambda do |submission|
               if submission.respond_to?(:course_id)
                 # Used when doing submission.exercise
                 where(course: submission.course)
               else
                 # Used when doing submissions.include(:exercises)
                 Exercise.joins(:submission)
               end
             end), foreign_key: :exercise_name, primary_key: :name

  has_one :submission_data, dependent: :delete
  after_save { submission_data&.save! }

  has_many :test_case_runs, -> { order(:id) }, dependent: :delete_all
  has_many :reviews, -> { order(:created_at) }, dependent: :delete_all do
    def latest
      order('created_at DESC').limit(1).first
    end
  end
  has_many :awarded_points, dependent: :nullify
  has_many :feedback_answers, dependent: :nullify

  validates :user, presence: true
  validates :course, presence: true
  validates :exercise_name, presence: true
  before_create :set_processing_attempts_started_at
  before_create :set_paste_key_if_paste_available

  after_save :kafka_update_progress
  after_destroy :kafka_update_progress

  def processing_time
    if processing_completed_at.nil? || processing_completed_at.nil?
      nil
    else
      (processing_completed_at - processing_attempts_started_at).round
    end
  end

  def self.to_be_reprocessed
    unprocessed
      .where('processing_tried_at IS NULL OR processing_tried_at < ?', Time.now - processing_retry_interval)
      .where('processing_began_at IS NULL OR processing_began_at < ?', Time.now - processing_resend_interval)
  end

  def self.unprocessed
    where(processed: false)
      .order('processing_priority DESC, processing_tried_at ASC, id ASC')
  end

  def self.unprocessed_count
    unprocessed.count
  end

  # How many times at most should a submission be (successfully) sent to a sandbox
  def self.max_attempts_at_processing
    3
  end

  before_create :randomize_secret_token

  def tests_ran?
    processed? && pretest_error.nil?
  end

  def result_url
    "#{SiteSetting.value(:baseurl_for_remote_sandboxes).sub(/\/+$/, '')}/submissions/#{id}/result"
  end

  def params
    ActiveSupport::JSON.decode(params_json) if params_json
  end

  def params=(value)
    if value.is_a?(Hash)
      value.each { |k, v| raise "Invalid submission param: #{k} = #{v}" unless valid_param?(k, v) }
      self.params_json = value.to_json
    elsif value.nil?
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

  def status(user)
    if !processed?
      :processing
    elsif !can_see_results?(user)
      :hidden
    elsif all_tests_passed?
      :ok
    elsif tests_ran?
      :fail
    else
      :error
    end
  end

  def can_see_results?(user)
    results_hidden = ((!exercise.nil? && exercise.hide_submission_results?) || course.hide_submission_results?)
    !results_hidden ||
      course.organization.teacher?(user) ||
      course.assistant?(user) ||
      user.administrator?
  end

  def points_list
    points.to_s.split(' ')
  end

  # Returns a query for all submissions (including this one) by the same user
  # for the same course and exercise
  def of_same_kind
    Submission.where(
      course_id: course_id,
      exercise_name: exercise_name,
      user_id: user_id
    )
  end

  # Returns the newest submission by the same user for the same exercise,
  # as long as it's newer than this submission
  def newest_of_same_kind
    of_same_kind.where(['created_at > ?', created_at]).order('created_at DESC').first
  end

  def review_dismissable?
    (requires_review? || requests_review?) &&
      !review_dismissed? &&
      !newer_submission_reviewed?
  end

  def unprocessed_submissions_before_this
    if !processed?
      i = 0
      self.class.unprocessed.select(:id).each do |s|
        return i if s.id == id
        i += 1
      end
      0 # race condition
    else
      0
    end
  end

  def downloadable_file_name
    "#{exercise_name}-#{id}.zip"
  end

  def test_case_records
    test_case_runs.map do |tcr|
      {
        name: tcr.test_case_name,
        successful: tcr.successful?,
        message: tcr.message,
        exception: tcr.exception ? ActiveSupport::JSON.decode(tcr.exception) : nil,
        detailed_message: tcr.detailed_message ? tcr.detailed_message : nil
      }
    end
  end

  delegate :return_file, to: :submission_data

  def return_file=(value)
    build_submission_data unless submission_data
    submission_data.return_file = value
  end

  def stdout
    build_submission_data unless submission_data
    submission_data.stdout
  end

  def stdout=(value)
    build_submission_data unless submission_data
    submission_data.stdout = value
  end

  def stderr
    build_submission_data unless submission_data
    submission_data.stderr
  end

  def stderr=(value)
    build_submission_data unless submission_data
    submission_data.stderr = value
  end

  def vm_log
    build_submission_data unless submission_data
    submission_data.vm_log
  end

  def vm_log=(value)
    build_submission_data unless submission_data
    submission_data.vm_log = value
  end

  def valgrind
    build_submission_data unless submission_data
    submission_data.valgrind
  end

  def valgrind=(value)
    build_submission_data unless submission_data
    submission_data.valgrind = value
  end

  def validations
    build_submission_data unless submission_data
    JSON.parse submission_data.validations if submission_data.validations.present?
  end

  def validations=(value)
    build_submission_data unless submission_data
    submission_data.validations = value
  end

  def raise_pretest_error_if_any
    unless pretest_error.nil?
      error = "Submission failed: #{pretest_error}."
      error << if stdout.blank?
        "\n\n(no stdout)"
      else
        "\n\nStdout:\n#{stdout}"
      end
      error << if stderr.blank?
        "\n\n(no stderr)"
      else
        "\n\nStderr:\n#{stderr}"
      end
      raise error
    end
  end

  def set_to_be_reprocessed!(priority = -200)
    self.processed = false
    self.times_sent_to_sandbox = 0
    self.processing_priority = priority
    self.processing_attempts_started_at = Time.now
    self.processing_tried_at = nil
    self.processing_began_at = nil
    self.processing_completed_at = nil
    self.sandbox = nil
    randomize_secret_token
    save!
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
    keys = submissions.map { |s| "(#{connection.quote(s.course_id)}, #{connection.quote(s.exercise_name)})" }
    keys.uniq!
    return if keys.empty?

    exercises = Exercise.where('(course_id, name) IN (' + keys.join(',') + ')')
    by_key = exercises.index_by { |e| [e.course_id, e.name] }
    for sub in submissions
      ex = by_key[[sub.course_id, sub.exercise_name]]
      sub.exercise = ex
    end
  end

  def paste_visible_for?(user)
    return false unless paste_available
    return true if exercise && exercise.completed_by?(user)
    return true if user.submissions.where(exercise_name: exercise.name, pretest_error: nil, all_tests_passed: true).any?
    !all_tests_passed
  end

  def readable_by?(user)
    user.administrator? || user.teacher?(course.organization) || user.assistant?(course) || user_id == user.id
  end

  def set_paste_key_if_paste_available
    self.paste_key = SecureRandom.urlsafe_base64 if paste_available?
  end

  def self.filter_fields!(submissions)
    submissions.map! do |sub|
      {
        id: sub.id,
        user_id: sub.user_id,
        pretest_error: sub.pretest_error,
        created_at: sub.created_at,
        exercise_name: sub.exercise_name,
        course_id: sub.course_id,
        processed: sub.processed,
        all_tests_passed: sub.all_tests_passed,
        points: sub.points,
        processing_tried_at: sub.processing_tried_at,
        processing_began_at: sub.processing_began_at,
        processing_completed_at: sub.processing_completed_at,
        times_sent_to_sandbox: sub.times_sent_to_sandbox,
        processing_attempts_started_at: sub.processing_attempts_started_at,
        params_json: sub.params_json,
        requires_review: sub.requires_review,
        requests_review: sub.requests_review,
        reviewed: sub.reviewed,
        message_for_reviewer: sub.message_for_reviewer,
        newer_submission_reviewed: sub.newer_submission_reviewed,
        review_dismissed: sub.review_dismissed,
        paste_available: sub.paste_available,
        message_for_paste: sub.message_for_paste,
        paste_key: sub.paste_key
      }
    end
  end

  private
    def set_processing_attempts_started_at
      self.processing_attempts_started_at = Time.now
    end

    def kafka_update_progress
      return if (!self.course.moocfi_id || self.course.moocfi_id.blank?) || !self.processed
      realtime = self.created_at > 1.hour.ago
      KafkaBatchUpdatePoints.create!(course_id: self.course_id, user_id: self.user_id, exercise_id: self.exercise.id, task_type: 'user_progress', realtime: realtime)
      KafkaBatchUpdatePoints.create!(course_id: self.course_id, user_id: self.user_id, exercise_id: self.exercise.id, task_type: 'user_points', realtime: realtime)
    end
end
