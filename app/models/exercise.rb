require 'shellwords'

class Exercise < ActiveRecord::Base
  self.include_root_in_json = false

  belongs_to :course

  has_many :available_points, :dependent => :delete_all

  has_many :submissions, -> { where("submissions.course_id = #{self.course_id}") }, :foreign_key => :exercise_name, :primary_key => :name

  has_many :feedback_answers, -> { where("feedback_answers.course_id = #{self.course_id}") }, :foreign_key => :exercise_name, :primary_key => :name
  has_many :unlocks, -> { where("unlocks.course_id = #{self.course_id}") }, :foreign_key => :exercise_name, :primary_key => :name

  validates :gdocs_sheet, :format => { :without => /\A(MASTER|PUBLIC)\z/ }

  scope :course_gdocs_sheet_exercises, lambda { |course, gdocs_sheet|
    where(:course_id => course.id, :gdocs_sheet => gdocs_sheet)
  }

  def relative_path
    name.gsub('-', '/')
  end

  def exercise_group
    self.course.exercise_group_by_name(self.exercise_group_name)
  end

  def exercise_group_name
    parts = name.split('-')
    parts.pop
    parts.join('-')
  end

  def belongs_to_exercise_group?(group)
    group.course.id == self.course_id && (self.exercise_group_name + '-').start_with?(group.name + '-')
  end

  def clone_path
    "#{course.clone_path}/#{self.relative_path}"
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
    "#{course.solution_path}/#{self.relative_path}"
  end

  def stub_path
    "#{course.stub_path}/#{self.relative_path}"
  end

  def stub_zip_file_path
    "#{course.stub_zip_path}/#{self.name}.zip"
  end

  def solution_zip_file_path
    "#{course.solution_zip_path}/#{self.name}.zip"
  end

  def solution
    Solution.new(self)
  end

  def set_submissions_by(user, value)
    @submissions_by ||= {}
    @submissions_by[user.id] = value
  end

  def submissions_by(user)
    @submissions_by ||= {}
    @submissions_by[user.id] ||= submissions.where(:user_id => user.id).to_a
  end

  def reload
    super
    @submissions_by = {}
  end

  # Whether a user may make submissions
  def submittable_by?(user)
    returnable? &&
      (user.administrator? ||
        (!expired_for?(user) && !hidden? && published? && !user.guest? && unlocked_for?(user)))
  end

  # Whether a user may see all metadata about the exercise
  def visible_to?(user)
    user.administrator? || (!hidden? && published? && unlock_spec_obj.permits_unlock_for?(user))
  end

  # Whether the user may see the scoreboard for the exercise
  def points_visible_to?(user)
    user.administrator? ||
      (
        !hidden? &&
        published? &&
        (course.locked_exercise_points_visible? || unlock_spec_obj.permits_unlock_for?(user))
      )
  end

  # Whether the user may download the exercise ZIP file
  def downloadable_by?(user)
    visible_to?(user) && unlocked_for?(user)
  end

  # Whether the exercise has been published (it may still be hidden)
  def published?
    !publish_time || publish_time <= Time.now
  end

  def deadline_for(user)
    deadline_spec_obj.deadline_for(user)
  end

  # Whether the deadline has passed
  def expired_for?(user)
    dl = deadline_for(user)
    dl != nil && dl < Time.now
  end

  # Whether a user has made a submission for this exercise
  def attempted_by?(user)
    submissions_by(user).any?(&:processed)
  end

  # Whether a user has made a submission with all test cases passing
  def completed_by?(user)
    submissions_by(user).any? do |s|
      s.pretest_error == nil && s.all_tests_passed?
    end
  end

  def requires_review?
    !available_review_points.empty?
  end

  # Whether a code review for this exercise exists for a submission made by 'user'.
  def reviewed_for?(user)
    self.submissions_by(user).any?(&:reviewed)
  end

  # Returns all reviewed submissions for this exercise for 'user'
  def reviewed_submissions_for(user)
    self.submissions_by(user).select(&:reviewed)
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
    AwardedPoint.course_user_points(course, user).map(&:name)
  end

  def missing_review_points_for(user)
    available_review_points - points_for(user)
  end

  def unlock_spec=(spec)
    check_is_json_array_of_strings(spec)
    super(spec)
    @unlock_spec_obj = nil
  end

  def unlock_spec_obj
    @unlock_spec_obj ||=
      if self.unlock_spec
        UnlockSpec.new(self, ActiveSupport::JSON.decode(self.unlock_spec))
      else
        UnlockSpec.new(self, [])
      end
  end

  def deadline_spec=(spec)
    check_is_json_array_of_strings(spec)
    super(spec)
    @deadline_spec_obj = DeadlineSpec.new(self, ActiveSupport::JSON.decode(spec))
  end

  def deadline_spec_obj
    @deadline_spec_obj ||=
      if self.deadline_spec
        DeadlineSpec.new(self, ActiveSupport::JSON.decode(self.deadline_spec))
      else
        DeadlineSpec.new(self, [])
      end
  end

  def requires_unlock?
    !unlock_spec_obj.empty?
  end

  def requires_explicit_unlock?
    deadline_spec_obj.depends_on_unlock_time?
  end

  def time_unlocked_for(user)
    UncomputedUnlock.resolve(course, user)
    self.unlocks.where(:user_id => user).where('valid_after IS NULL OR valid_after < ?', Time.now).first.andand.created_at
  end

  def unlocked_for?(user)
    !requires_unlock? || time_unlocked_for(user)
  end

  def unlockable_for?(user)
    requires_explicit_unlock? && !unlocked_for?(user) && unlock_spec_obj.permits_unlock_for?(user)
  end

  def solution_visible_after=(new_value)
    super(DateAndTimeUtils.to_time(new_value, :prefer_end_of_day => true))
  end

  def options=(new_options)
    new_options = self.class.default_options.merge(new_options)
    self.deadline_spec = to_json_array(new_options["deadline"])
    self.unlock_spec = to_json_array(new_options["unlocked_after"])
    self.publish_time = new_options["publish_time"]
    self.gdocs_sheet = new_gdocs_sheet(new_options["points_visible"], new_options["gdocs_sheet"])
    self.hidden = new_options["hidden"]
    self.returnable_forced = new_options["returnable"]
    self.solution_visible_after = new_options["solution_visible_after"]
    self.runtime_params = parse_runtime_params(new_options["runtime_params"])
    self.valgrind_strategy = new_options["valgrind_strategy"]
  end

  # Whether this exercise accepts submissions at all.
  # TMC may be used to distribute exercise templates without tests.
  def returnable?
    if returnable_forced != nil
      returnable_forced # may be true or false
    else
      has_tests?
    end
  end

  # The memory limit in megabytes or nil if not set.
  # Limited by the global limit in site.yml (if any).
  # Not configurable per-exercise yet but possibly in the future.
  def memory_limit
    global_limit = SiteSetting.value('memory_limit')
    if global_limit != nil
      global_limit.to_i
    else
      nil
    end
  end

  def runtime_params_array
    ActiveSupport::JSON.decode(runtime_params)
  end

  def self.default_options
    {
      "deadline" => nil,
      "publish_time" => nil,
      "gdocs_sheet" => nil,
      "points_visible" => true,
      "hidden" => false,
      "returnable" => nil,
      "solution_visible_after" => nil,
      "valgrind_strategy" => "fail".freeze,
      "runtime_params" => nil
    }
  end

  def submissions_having_feedback
    submissions.where('EXISTS (SELECT 1 FROM feedback_answers WHERE feedback_answers.submission_id = submissions.id)')
  end

  def self.count_completed(users, exercises)
    return 0 if exercises.empty?

    s = Submission.arel_table

    user_ids = users.map(&:id)
    exercise_keys = exercises.map {|e| "(#{e.course_id}, #{quote_value(e.name)})" }

    query =
      s.
      project(Arel.sql('COUNT(DISTINCT (course_id, exercise_name, user_id))').as('count')).
      where(s[:user_id].in(user_ids)).
      where(Arel.sql("(course_id, exercise_name) IN (#{exercise_keys.join(',')})")).
      where(s[:pretest_error].eq(nil)).
      where(s[:all_tests_passed].eq(true))

    results = connection.execute(query.to_sql)
    begin
      results[0]['count'].to_i
    ensure
      results.clear
    end
  end

private
  def new_gdocs_sheet(enabled, sheetname)
    return nil unless enabled
    return sheetname.to_s unless sheetname.blank?
    return name_to_gdocs_sheet
  end

  def name_to_gdocs_sheet
    sheetname = self.name.split('-')[0..-2].join('-')
    sheetname.empty? ? "root" : sheetname
  end

  def to_json_array(value)
    if value != nil
      value = [value] unless value.is_a?(Array)
      value.to_json
    else
      "[]"
    end
  end

  def check_is_json_array_of_strings(str)
    array = ActiveSupport::JSON.decode(str)
    raise "JSON array expected" if !array.is_a?(Array)
    raise "JSON array of strings expected" if array.any? {|a| !a.is_a?(String) }
  end

  def parse_runtime_params(raw_params)
    if raw_params == nil
      "[]"
    elsif raw_params.is_a?(String)
      to_json_array(Shellwords::shellwords(raw_params))
    elsif raw_params.is_a?(Array)
      to_json_array(raw_params)
    else
      raise "Invalid runtime_params: #{raw_params.inspect}"
    end
  end
end
