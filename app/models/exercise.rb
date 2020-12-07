# frozen_string_literal: true

require 'shellwords'

class Exercise < ActiveRecord::Base
  self.include_root_in_json = false
  include Swagger::Blocks

  swagger_schema :ExerciseWithPoints do
    key :required, %i[
      id name publish_time solution_visible_after
      deadline disabled available_points
    ]

    property :id, type: :integer, example: 1
    property :name, type: :string, example: 'Exercise name'
    property :publish_time, type: :string, format: 'date-time', example: '2016-10-24T14:06:36.730+03:00'
    property :solution_visible_after, type: :string, format: 'date-time', example: '2016-10-24T14:06:36.730+03:00'
    property :deadline, type: :string, format: 'date-time', example: '2016-10-24T14:06:36.730+03:00'
    property :soft_deadline, type: :string, format: 'date-time', example: '2016-10-24T14:06:36.730+03:00'
    property :disabled, type: :boolean, example: false
    property :available_points, type: :array do
      items do
        key :'$ref', :AvailablePoint
      end
    end
  end

  swagger_schema :CoreExercise do
    key :required, %i[
      course_name course_id code_review_requests_enabled run_tests_locally_action_enabled
      exercise_name exercise_id unlocked_at deadline submissions
    ]

    property :course_name, type: :string, example: 'course'
    property :course_id, type: :integer, example: 1
    property :code_review_requests_enabled, type: :boolean, example: true
    property :run_tests_locally_action_enabled, type: :boolean, example: true
    property :exercise_name, type: :string, example: 'exercise'
    property :exercise_id, type: :integer, example: 1
    property :unlocked_at, type: :string, format: 'date-time', example: '2016-12-05T12:00:00.000+03:00'
    property :deadline, type: :string, format: 'date-time', example: '2016-12-24T00:00:00.000+03:00'
    property :submissions, type: :array do
      items do
        key :'$ref', :CoreSubmission
      end
    end
  end

  swagger_schema :CoreExerciseQueryDetails do
    property :id, type: :integer, example: 1
    property :checksum, type: :string, example: 'f25e139769b2688e213938456959eeaf'
  end

  swagger_schema :CoreExerciseDetails do
    key :required, %i[id name locked deadline_description deadline checksum return_url zip_url returnable requires_review attempted
                      completed reviewed all_review_point_given memory_limit runtime_params valgrind_strategy code_review_requests_enabled
                      run_tests_locally_action_enabled exercise_submissions_url]

    property :id, type: :integer, example: 1
    property :name, type: :string, example: 'Exercise name'
    property :locked, type: :boolean, example: false
    property :deadline_description, type: :string, example: '2016-02-29 23:59:00 +0200'
    property :deadline, type: :string, format: 'date-time', example: '2016-02-29T23:59:00.000+02:00'
    property :checksum, type: :string, example: 'f25e139769b2688e213938456959eeaf'
    property :return_url, type: :string, example: 'https://tmc.mooc.fi/api/v8/core/exercises/1337/submissions'
    property :zip_url, type: :string, example: 'https://tmc.mooc.fi/api/v8/core/exercises/4272/download'
    property :returnable, type: :boolean, example: true
    property :requires_review, type: :boolean, example: false
    property :attempted, type: :boolean, example: false
    property :completed, type: :boolean, example: false
    property :reviewed, type: :boolean, example: false
    property :all_review_points_given, type: :boolean, example: true
    property :memory_limit, type: :integer, example: 1024
    property :runtime_params, type: :array do
      items do
        key :type, :string
        key :example, '-Xss64M'
      end
    end
    property :valgrind_strategy, type: :string, example: 'fail'
    property :code_review_requests_enabled, type: :boolean, example: false
    property :run_tests_locally_action_enabled, type: :boolean, example: true
    property :exercise_submissions_url, type: :string, example: 'https://tmc.mooc.fi/api/v8/core/exercises/1337/solution/download'
    # These are returned after submission
    property :latest_submission_url, type: :string, example: 'https://tmc.mooc.fi/api/v8/core/exercises/1337'
    property :latest_submission_id, type: :integer, example: 13_337
    # This is returned if user == admin
    property :solution_zip_url, type: :string, example: 'http://tmc.mooc.fi/api/v8/core/submissions/1337/download'
  end

  belongs_to :course

  has_many :available_points, dependent: :delete_all

  has_many :submissions,
           (lambda do |exercise|
             if exercise.respond_to?(:course_id)
               # Used when doing exercise.submissions
               where(course: exercise.course)
             else
               # Used when doing exercises.includes(:submissions)
               Submission.joins(:exercise)
             end
           end), foreign_key: :exercise_name, primary_key: :name

  has_many :feedback_answers, ->(exercise) { where(course: exercise.course) }, foreign_key: :exercise_name, primary_key: :name
  has_many :unlocks, ->(exercise) { where(course: exercise.course) }, foreign_key: :exercise_name, primary_key: :name

  validates :gdocs_sheet, format: { without: /\A(MASTER|PUBLIC)\z/ }

  scope :course_gdocs_sheet_exercises, lambda { |course, gdocs_sheet, hidden = false|
    res = where(course_id: course.id, gdocs_sheet: gdocs_sheet)
    res = res.where(hide_submission_results: false) unless hidden
    res
  }

  enum disabled_status: %i[enabled disabled]
  enum paste_visibility: %i[open protected no-tests-public everyone]

  def relative_path
    name.tr('-', '/')
  end

  def exercise_group
    course.exercise_group_by_name(exercise_group_name)
  end

  def exercise_group_name
    parts = name.split('-')
    parts.pop
    parts.join('-')
  end

  def part
    begin
      return exercise.group_name.tr('^0-9', '').to_i
    rescue => ex
      return 0
    end
  end

  def belongs_to_exercise_group?(group)
    group.course.id == course_id && (exercise_group_name + '-').start_with?(group.name + '-')
  end

  def clone_path
    "#{course.clone_path}/#{relative_path}"
  end

  def exercise_dir
    ExerciseDir.get(clone_path)
  end

  def try_get_exercise_dir
    ExerciseDir.try_get(clone_path)
  end

  def exercise_type
    ExerciseDir.exercise_type(clone_path)
  end

  def solution_path
    "#{course.solution_path}/#{relative_path}"
  end

  def stub_path
    "#{course.stub_path}/#{relative_path}"
  end

  def stub_zip_file_path
    "#{course.stub_zip_path}/#{name}.zip"
  end

  def solution_zip_file_path
    "#{course.solution_zip_path}/#{name}.zip"
  end

  def solution
    Solution.new(self)
  end

  def set_submissions_by!(user, value)
    @submissions_by ||= {}
    @submissions_by[user.id] = value
  end

  def submissions_by(user)
    @submissions_by ||= {}
    @submissions_by[user.id] ||= submissions.where(user_id: user.id).to_a
  end

  def reload
    super
    @submissions_by = {}
  end

  # Whether a user may make submissions
  def submittable_by?(user)
    returnable? &&
      (user.administrator? || user.teacher?(course.organization) || user.assistant?(course) ||
        (!expired_for?(user) && !hidden? && published? && !disabled? && !user.guest? && unlocked_for?(user)))
  end

  # Whether a user may see all metadata about the exercise
  def visible_to?(user)
    user.administrator? || user.teacher?(course.organization) || user.assistant?(course) ||
      _fast_visible? && (unlocked_for?(user) || unlock_spec_obj.permits_unlock_for?(user))
  end

  def _fast_visible?
    !hidden? && !disabled? && published?
  end

  # Whether the user may see the scoreboard for the exercise
  def points_visible_to?(user)
    user.administrator? ||
      user.teacher?(course.organization) ||
      (
        !hidden? &&
        published? &&
        !disabled? &&
        (course.locked_exercise_points_visible? || unlock_spec_obj.permits_unlock_for?(user)) &&
        !hide_submission_results &&
        !course.hide_submission_results
      )
  end

  # Whether the user may download the exercise ZIP file
  def downloadable_by?(user)
    user.assistant?(course) || visible_to?(user) && unlocked_for?(user)
  end

  # Whether the exercise has been published (it may still be hidden)
  def published?
    !publish_time || publish_time <= Time.now
  end

  delegate :deadline_for, to: :deadline_spec_obj

  def soft_deadline_for(user)
    soft_deadline_spec_obj.deadline_for(user)
  end

  # Whether the deadline has passed
  def expired_for?(user)
    Exercise.deadline_expired?(deadline_for(user))
  end

  def soft_deadline_expired_for?(user)
    Exercise.deadline_expired?(soft_deadline_for(user))
  end

  # Whether a user has made a submission for this exercise
  def attempted_by?(user)
    submissions_by(user).any?(&:processed)
  end

  # Whether a user has made a submission with all test cases passing
  def completed_by?(user)
    submissions_by(user).any? do |s|
      s.pretest_error.nil? && s.all_tests_passed?
    end
  end

  def requires_review?
    !available_review_points.empty?
  end

  # Whether a code review for this exercise exists for a submission made by 'user'.
  def reviewed_for?(user)
    submissions_by(user).any?(&:reviewed)
  end

  # Returns all reviewed submissions for this exercise for 'user'
  def reviewed_submissions_for(user)
    submissions_by(user).select(&:reviewed)
  end

  # Whether all of the required code review points have been given.
  # Returns true if the exercise doesn't require code review.
  def all_review_points_given_for?(user)
    arp = available_review_points
    return true if arp.empty? # optimization
    user.has_points?(course, arp)
  end

  def available_review_points
    # use 'select' instead of 'where' to use cached value of available_points
    available_points.to_a.select(&:requires_review).map(&:name)
  end

  def points_for(user)
    AwardedPoint.exercise_user_points(self, user).map(&:name)
  end

  def missing_review_points_for(user)
    available_review_points - points_for(user)
  end

  def unlock_spec=(spec)
    check_is_json_array_of_strings(spec)
    @unlock_spec_obj = UnlockSpec.from_str(course, spec)
    super(@unlock_spec_obj.empty? ? nil : spec)
  end

  def unlock_spec_obj
    @unlock_spec_obj ||= UnlockSpec.from_str(course, unlock_spec)
  end

  def unlock_conditions
    unlock_spec_obj.raw_spec
  end

  def deadline_spec=(spec)
    check_is_json_array_of_strings(spec)
    super(spec)
    @deadline_spec_obj = DeadlineSpec.new(self, ActiveSupport::JSON.decode(spec))
  end

  def soft_deadline_spec=(spec)
    check_is_json_array_of_strings(spec)
    super(spec)
    @soft_deadline_spec_obj = DeadlineSpec.new(self, ActiveSupport::JSON.decode(spec))
  end

  def deadline_spec_obj
    @deadline_spec_obj ||= new_deadline_spec_obj(deadline_spec)
  end

  def soft_deadline_spec_obj
    @soft_deadline_spec_obj ||= new_deadline_spec_obj(soft_deadline_spec)
  end

  def static_deadline
    deadline_spec_obj.static_deadline_spec
  end

  def unlock_deadline
    deadline_spec_obj.unlock_deadline_spec
  end

  def soft_static_deadline
    soft_deadline_spec_obj.static_deadline_spec
  end

  def soft_unlock_deadline
    soft_deadline_spec_obj.unlock_deadline_spec
  end

  def has_unlock_deadline?
    unlock_deadline.present? || soft_unlock_deadline.present?
  end

  def requires_unlock?
    !unlock_spec.nil?
  end

  def requires_explicit_unlock?
    deadline_spec_obj.depends_on_unlock_time?
  end

  def time_unlocked_for(user, resolve_unlocks = true)
    UncomputedUnlock.resolve(course, user) if resolve_unlocks
    unlocks.where(user_id: user).find_by('valid_after IS NULL OR valid_after < ?', Time.now).andand.created_at
  end

  def unlocked_for?(user, resolve_unlocks = true)
    !requires_unlock? || time_unlocked_for(user, resolve_unlocks)
  end

  def unlockable_for?(user)
    requires_explicit_unlock? && !unlocked_for?(user) && unlock_spec_obj.permits_unlock_for?(user)
  end

  def solution_visible_after=(new_value)
    super(DateAndTimeUtils.to_time(new_value, prefer_end_of_day: true))
  end

  # Ignore some options if already set; to keep changes done in UI.
  def options=(new_options)
    new_options = self.class.default_options.merge(new_options)

    self.deadline_spec = to_json_array(new_options['deadline']) if deadline_spec.nil?
    self.soft_deadline_spec = to_json_array(new_options['soft_deadline']) if soft_deadline_spec.nil?
    self.unlock_spec = to_json_array(new_options['unlocked_after']) if unlock_spec.nil?
    self.publish_time = new_options['publish_time']
    self.gdocs_sheet = new_gdocs_sheet(new_options['points_visible'], new_options['gdocs_sheet'])
    self.hidden = new_options['hidden']
    self.returnable_forced = new_options['returnable']
    self.solution_visible_after = new_options['solution_visible_after']
    self.runtime_params = parse_runtime_params(new_options['runtime_params'])
    self.valgrind_strategy = new_options['valgrind_strategy']
    self.code_review_requests_enabled = new_options['code_review_requests_enabled']
    self.run_tests_locally_action_enabled = new_options['run_tests_locally_action_enabled']
  end

  # Whether this exercise accepts submissions at all.
  # TMC may be used to distribute exercise templates without tests.
  def returnable?
    if !returnable_forced.nil?
      returnable_forced # may be true or false
    else
      has_tests? && course.initial_refresh_ready?
    end
  end

  # The memory limit in megabytes or nil if not set.
  # Limited by the global limit in site.yml (if any).
  # Not configurable per-exercise yet but possibly in the future.
  def memory_limit
    global_limit = SiteSetting.value('memory_limit')
    global_limit&.to_i
  end

  def runtime_params_array
    ActiveSupport::JSON.decode(runtime_params)
  end

  def code_review_requests_enabled?
    course.code_review_requests_enabled? && self[:code_review_requests_enabled]
  end

  def self.default_options
    {
      'deadline' => nil,
      'soft_deadline' => nil,
      'publish_time' => nil,
      'gdocs_sheet' => nil,
      'points_visible' => true,
      'hidden' => false,
      'returnable' => nil,
      'solution_visible_after' => nil,
      'valgrind_strategy' => 'fail',
      'runtime_params' => nil,
      'code_review_requests_enabled' => true,
      'run_tests_locally_action_enabled' => true
    }
  end

  def submissions_having_feedback
    submissions.where('EXISTS (SELECT 1 FROM feedback_answers WHERE feedback_answers.submission_id = submissions.id)')
  end

  def self.count_completed(users, exercises)
    return 0 if exercises.empty?

    s = Submission.arel_table

    user_ids = users.map(&:id)
    exercise_keys = exercises.map { |e| "(#{e.course_id}, #{quote_value(e.name, nil)})" }

    query = s.project(Arel.sql('COUNT(DISTINCT (course_id, exercise_name, user_id))').as('count'))
             .where(s[:user_id].in(user_ids))
             .where(Arel.sql("(course_id, exercise_name) IN (#{exercise_keys.join(',')})"))
             .where(s[:pretest_error].eq(nil))
             .where(s[:all_tests_passed].eq(true))

    results = connection.execute(query.to_sql)
    begin
      results[0]['count'].to_i
    ensure
      results.clear
    end
  end

  def toggle_submission_result_visiblity
    self.hide_submission_results = !hide_submission_results
    save!
  end

  def self.deadline_expired?(deadline, time = Time.now)
    !deadline.nil? && deadline < time
  end

  private

    def new_deadline_spec_obj(spec)
      if spec
        DeadlineSpec.new(self, ActiveSupport::JSON.decode(spec))
      else
        DeadlineSpec.new(self, [])
      end
    end

    def new_gdocs_sheet(enabled, sheetname)
      return nil unless enabled
      return sheetname.to_s if sheetname.present?
      name_to_gdocs_sheet
    end

    def name_to_gdocs_sheet
      sheetname = name.split('-')[0..-2].join('-')
      sheetname.empty? ? 'root' : sheetname
    end

    def to_json_array(value)
      if !value.nil?
        value = [value] unless value.is_a?(Array)
        value.to_json
      else
        '[]'
      end
    end

    def check_is_json_array_of_strings(str)
      return if str.nil?
      array = ActiveSupport::JSON.decode(str)
      raise 'JSON array expected' unless array.is_a?(Array)
      raise 'JSON array of strings expected' if array.any? { |a| !a.is_a?(String) }
    end

    def parse_runtime_params(raw_params)
      if raw_params.nil?
        '[]'
      elsif raw_params.is_a?(String)
        to_json_array(Shellwords.shellwords(raw_params))
      elsif raw_params.is_a?(Array)
        to_json_array(raw_params)
      else
        raise "Invalid runtime_params: #{raw_params.inspect}"
      end
    end
end
