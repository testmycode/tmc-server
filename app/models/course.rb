# typed: strict
# frozen_string_literal: true

require 'system_commands'
require 'date_and_time_utils'

class Course < ApplicationRecord
  extend T::Sig
  include SystemCommands
  include Swagger::Blocks

  swagger_schema :Course do
    key :required, %i[name hide_after hidden cache_version spreadsheet_key hidden_if_registered_after
                      refreshed_at locked_exercise_points_visible description paste_visibility formal_name
                      certificate_downloadable certificate_unlock_spec organization_id disabled_status
                      title material_url course_template_id hide_submission_results external_scoreboard_url]

    property :name, type: :string, example: 'organizationid-coursename'
    property :hide_after, type: :string, example: '2016-10-10T13:22:19.554+03:00'
    property :hidden, type: :boolean, example: false
    property :cache_version, type: :integer, example: 1
    property :spreadsheet_key, type: :string
    property :hidden_if_registered_after, type: :string
    property :refreshed_at, type: :string, example: '2016-10-10T13:22:36.871+03:00'
    property :locked_exercise_points_visible, type: :boolean, example: true
    property :description, type: :string, example: ''
    property :paste_visibility, type: :integer
    property :formal_name, type: :string
    property :certificate_downloadable, type: :boolean, example: false
    property :certificate_unlock_spec, type: :string
    property :organization_id, type: :integer, example: 1
    property :disabled_status, type: :string, example: 'enabled'
    property :title, type: :string, example: 'testcourse'
    property :material_url, type: :string, example: ''
    property :course_template_id, type: :integer, example: 1
    property :hide_submission_results, type: :boolean, example: false
    property :external_scoreboard_url, type: :string
    property :organization_slug, type: :string, example: 'hy'
  end

  swagger_schema :CoreCourseDetails do
    key :required, %i[id name title description details_url unlock_url reviews_url comet_url spyware_urls unlockables exercises]

    property :id, type: :integer, example: 13
    property :name, type: :string, example: 'organizationid-coursename'
    property :title, type: :string, example: 'coursetitle'
    property :description, type: :string, example: 'description of the course'
    property :details_url, type: :string, example: 'http://tmc.mooc.fi/api/v8/core/courses/13'
    property :unlock_url, type: :string, example: 'https://tmc.mooc.fi/api/v8/core/courses/13/unlock'
    property :reviews_url, type: :string, example: 'https://tmc.mooc.fi/api/v8/core/courses/13/reviews'
    property :comet_url, type: :string, example: 'https://tmc.mooc.fi:8443/comet'
    property :spyware_urls, type: :array do
      items do
        key :type, :string
        key :example, 'http://mooc.spyware.testmycode.net/'
      end
    end
    property :unlockables, type: :array do
      items do
        key :type, :string
        key :example, ''
      end
    end
    property :exercises, type: :array do
      items do
        key :'$ref', :CoreExerciseDetails
      end
    end
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def course_as_json
    {
      name: name,
      hide_after: hide_after,
      hidden: hidden,
      cache_version: cached_version,
      spreadsheet_key: spreadsheet_key,
      hidden_if_registered_after: hidden_if_registered_after,
      refreshed_at: refreshed_at,
      locked_exercise_points_visible: locked_exercise_points_visible,
      paste_visibility: paste_visibility,
      formal_name: formal_name,
      certificate_downloadable: certificate_downloadable,
      certificate_unlock_spec: certificate_unlock_spec,
      organization_id: organization_id,
      disabled_status: disabled_status,
      title: title,
      description: description,
      material_url: material_url,
      course_template_id: course_template_id,
      hide_submission_results: hide_submission_results,
      external_scoreboard_url: external_scoreboard_url,
      organization_slug: organization_slug,
    }
  end

  swagger_schema :CourseLinks do
    key :required, %i[id name title description details_url unlock_url reviews_url comet_url spyware_urls]

    property :id, type: :integer, example: 13
    property :name, type: :string, example: 'organizationid-coursename'
    property :title, type: :string, example: 'coursetitle'
    property :description, type: :string, example: 'description of the course'
    property :details_url, type: :string, example: 'https://tmc.mooc.fi/api/v8/core/courses/13'
    property :unlock_url, type: :string, example: 'https://tmc.mooc.fi/api/v8/core/courses/13/unlock'
    property :reviews_url, type: :string, example: 'https://tmc.mooc.fi/api/v8/core/courses/13/reviews'
    property :comet_url, type: :string, example: 'https://tmc.mooc.fi:8443/comet'
    property :spyware_urls, type: :array do
      items do
        key :type, :string
        key :example, 'http://mooc.spyware.testmycode.net/'
      end
    end
  end

  swagger_schema :CourseBasicInfo do
    key :required, %i[id name organization_id title]

    property :id, type: :integer, example: 13
    property :name, type: :string, example: 'organizationid-coursename'
    property :organization_id, type: :integer, example: 1
    property :title, type: :string, example: 'testcourse'
  end

  sig { params(view_context: ActionView::Base).returns(T::Hash[String, T.untyped]) }
  def links_as_json(view_context)
    {
      id: id,
      name: name,
      title: title,
      description: description,
      details_url: view_context.api_v8_core_course_url(self),
      unlock_url: view_context.api_v8_core_course_unlock_url(self),
      reviews_url: view_context.api_v8_core_course_reviews_url(self),
      comet_url: '',
      spyware_urls: SiteSetting.value('spyware_servers')
    }.as_json
  end

  self.include_root_in_json = false

  validates :name,
            presence: true,
            uniqueness: true,
            format: {
              without: / /,
              message: 'should not contain white spaces'
            }
  validates :title,
            presence: true,
            length: { within: 1..80 }
  validates :description, length: { maximum: 512 }
  validate :check_name_length

  before_validation :save_template
  # If made from template, make sure cached_version is not out of sync.
  before_save :set_cached_version
  validates :source_url, presence: true
  # validates :custom_points_url,
  #          format: {
  #            with: /(\Ahttps?:\/\/|\A\z|^$)/,
  #            message: 'should begin with http:// or https://'
  #          }
  validate :check_external_scoreboard_url
  validates :moocfi_id,
            uniqueness: true,
            format: {
              with: /\A[0-9a-f]{32}\z|\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/,
              message: "should be a hash ID. You can find it from mooc.fi from your course's details. Please leave this empty if your course is not in mooc.fi (note that mooc.fi and tmc.mooc.fi are separate services)"
            },
            if: -> (x) { x.moocfi_id.present? }

  has_many :exercises, dependent: :delete_all
  has_many :submissions, dependent: :delete_all
  has_many :users, -> { distinct }, through: :submissions
  has_many :available_points, through: :exercises
  has_many :awarded_points, dependent: :delete_all
  has_many :test_scanner_cache_entries, dependent: :delete_all
  has_many :feedback_questions, dependent: :delete_all
  has_many :feedback_answers # destroyed transitively when questions are destroyed
  has_many :unlocks, dependent: :delete_all
  has_many :uncomputed_unlocks, dependent: :delete_all
  has_many :course_notifications, dependent: :delete_all
  has_many :certificates
  has_many :assistantships, dependent: :destroy
  has_many :assistants, through: :assistantships, source: :user

  belongs_to :course_template
  belongs_to :organization

  scope :with_certificates_for, ->(user) { select { |c| c.visible_to?(user) && c.certificate_downloadable_for?(user) } }

  enum :disabled_status, { enabled: 0, disabled: 1 }
  enum :paste_visibility, { open: 0, secured: 1, 'no-tests-public': 2, everyone: 3, 'completed-only': 4 }

  sig { void }
  def destroy
    # Optimization: delete dependent objects quickly.
    # Rails' :dependent => :delete_all is very slow.
    # Even self.association.delete_all first does a SELECT.
    # This relies on the database to cascade deletes.
    ActiveRecord::Base.connection.execute("DELETE FROM courses WHERE id = #{id}")
    assistantships.each(&:destroy!) # apparently this is not performed automatically with optimized destroy

    # Delete cache.
    delete_cache # Would be an after_destroy callback normally
  end

  scope :ongoing, -> { where(['hide_after IS NULL OR hide_after > ?', Time.now]) }
  scope :expired, -> { where(['hide_after IS NOT NULL AND hide_after <= ?', Time.now]) }
  scope :assisted_courses, ->(user, organization) do
    joins(:assistantships)
      .where(assistantships: { user_id: user.id })
      .where(organization_id: organization.id)
  end
  scope :participated_courses, ->(user, organization) do
    joins(:awarded_points)
      .where(awarded_points: { user_id: user.id })
      .where(organization_id: organization.id)
      .group('courses.id')
  end

  sig { params(course_template: CourseTemplate).returns(Course) }
  def self.new_from_template(course_template)
    Course.new(name: course_template.name,
               title: course_template.title,
               description: course_template.description,
               material_url: course_template.material_url,
               cached_version: course_template.cached_version,
               course_template: course_template)
  end

  delegate :git_branch, to: :course_template_obj

  delegate :slug, to: :organization, prefix: true

  delegate :source_url, to: :course_template_obj

  delegate :source_backend, to: :course_template_obj

  delegate :git_branch=, to: :course_template_obj

  delegate :source_url=, to: :course_template_obj

  delegate :source_backend=, to: :course_template_obj

  sig { params(user: User).returns(T::Boolean) }
  def visible_to?(user)
    hide_after = self.hide_after
    hidden_if_registered_after = self.hidden_if_registered_after
    user.administrator? ||
      user.teacher?(organization) ||
      user.assistant?(self) || (
        initial_refresh_ready? &&
        !disabled? &&
        !hidden &&
        (hide_after.nil? || hide_after > Time.now) &&
        (
          hidden_if_registered_after.nil? ||
          hidden_if_registered_after > Time.now ||
          (!user.guest? && hidden_if_registered_after > user.created_at)
        )
      )
  end

  sig { params(x: T.untyped).void }
  def hide_after=(x)
    # Active Record casts any Time to TimeWithZone; Tapioca types the writer as TimeWithZone only.
    super(T.unsafe(DateAndTimeUtils.to_time(x, prefer_end_of_day: true)))
  end

  sig { params(x: T.untyped).void }
  def hidden_if_registered_after=(x)
    super(T.unsafe(DateAndTimeUtils.to_time(x, prefer_end_of_day: false)))
  end

  # This could eventually be made a hstore
  sig { params(new_options: T::Hash[String, T.untyped]).void }
  def options=(new_options)
    self.hide_after = new_options['hide_after'].presence

    self.hidden_if_registered_after = new_options['hidden_if_registered_after'].presence

    self.hidden = !!new_options['hidden']
    self.spreadsheet_key = new_options['spreadsheet_key']

    self.paste_visibility = new_options['paste_visibility']
    self.locked_exercise_points_visible = if !new_options['locked_exercise_points_visible'].nil?
      new_options['locked_exercise_points_visible']
    else
      true
    end

    self.formal_name = new_options['formal_name'].presence

    self.certificate_downloadable = !!new_options['certificate_downloadable']

    self.certificate_unlock_spec = new_options['certificate_unlock_spec'].presence
  end

  sig { params(exercises: T.nilable(T::Enumerable[Exercise])).returns(T::Array[String]) }
  def gdocs_sheets(exercises = nil)
    exercises ||= self.exercises.select { |ex| !ex.hidden? && ex.published? }
    exercises.filter_map(&:gdocs_sheet).uniq
  end

  sig { returns(String) }
  def self.cache_root
    "#{FileStore.root}/course"
  end

  delegate :increment_cached_version, to: :course_template_obj

  delegate :cache_path, to: :course_template_obj

  # Holds a clone of the course repository
  sig { returns(String) }
  def clone_path
    "#{cache_path}/clone"
  end

  sig { returns(T.nilable(String)) }
  def git_revision
    Dir.chdir clone_path do
      output = `git rev-parse --verify HEAD`
      output.strip if $?.success?
    end
  rescue StandardError
    nil
  end

  sig { returns(String) }
  def solution_path
    "#{cache_path}/solution"
  end

  sig { returns(String) }
  def stub_path
    "#{cache_path}/stub"
  end

  sig { returns(String) }
  def stub_zip_path
    "#{cache_path}/stub_zip"
  end

  sig { returns(String) }
  def solution_zip_path
    "#{cache_path}/solution_zip"
  end

  sig { params(force_reload: T::Boolean).returns(T::Array[ExerciseGroup]) }
  def exercise_groups(force_reload = false)
    @groups = T.let(nil, T.nilable(T::Array[ExerciseGroup])) if force_reload
    @groups ||= T.let(begin
      result = exercises.all.map(&:exercise_group_name).uniq
                        .map { |gname| ExerciseGroup.new(self, gname) }

      loop do
        all_parents = result.filter_map(&:parent_name)
        new_parents = all_parents.reject { |pn| result.any? { |eg| eg.name == pn } }.uniq
        break if new_parents.empty?
        result += new_parents.map { |pn| ExerciseGroup.new(self, pn) }
      end

      result.sort
    end, T.nilable(T::Array[ExerciseGroup]))
  end

  sig { params(name: String, force_reload: T::Boolean).returns(T.nilable(ExerciseGroup)) }
  def exercise_group_by_name(name, force_reload = false)
    exercise_groups(force_reload).find { |eg| eg.name == name }
  end

  # Returns exercises in group `name`, or whose full name is `name`.
  sig { params(name: String, force_reload: T::Boolean).returns(T::Array[Exercise]) }
  def exercises_by_name_or_group(name, force_reload = false)
    group = exercise_group_by_name(name, force_reload)
    exercises.to_a.select { |ex| ex.name == name || (group && ex.belongs_to_exercise_group?(group)) }
  end

  # Set of names of the exercises in `exercises_to_check` the user may open, including those that need no unlock.
  # Batched form of Exercise#unlocked_for? without resolving pending unlocks.
  sig { params(user: User, exercises_to_check: T::Enumerable[Exercise]).returns(T::Set[T.nilable(String)]) }
  def unlocked_exercise_names_for(user, exercises_to_check)
    from_rows = unlocks.where(user_id: user.id).where('valid_after IS NULL OR valid_after < ?', Time.now).pluck(:exercise_name).to_set
    exercises_to_check.select do |ex|
      if !ex.requires_unlock?
        true
      elsif ex.unlocked_by_date?
        ex.unlock_time_by_date
      else
        from_rows.include?(ex.name)
      end
    end.to_set(&:name)
  end

  sig { params(user: User).returns(T::Array[Exercise]) }
  def unlockable_exercises_for(user)
    UncomputedUnlock.resolve(self, user)
    unlocked = unlocks.where(user_id: user.id).pluck(:exercise_name)
    exercises.to_a.select { |ex| unlocked.exclude?(ex.name) && ex.unlockable_for?(user) }
  end

  sig { params(options: T.nilable(T::Hash[Symbol, T.untyped])).returns(T.self_type) }
  def reload(options = nil)
    super
    @groups = nil
    self
  end

  sig { params(current_user_id: Integer).returns(CourseTemplateRefresh) }
  def refresh(current_user_id)
    CourseTemplateRefresh.create!(user_id: current_user_id, course_template_id: self.course_template_id)
  end

  sig { void }
  def delete_cache
    FileUtils.rm_rf cache_path if custom?
  end

  sig { returns(T::Array[String]) }
  def self.valid_source_backends
    ['git']
  end

  sig { returns(String) }
  def self.default_source_backend
    'git'
  end

  sig { returns(T.nilable(ActiveSupport::TimeWithZone)) }
  def time_of_first_submission
    sub = submissions.order(:created_at).limit(1).first
    sub&.created_at
  end

  sig { returns(T.nilable(ActiveSupport::TimeWithZone)) }
  def time_of_last_submission
    sub = submissions.order(created_at: :desc).limit(1).first
    sub&.created_at
  end

  sig { returns(ActiveRecord::Relation) }
  def reviews_required
    submissions.where(
      requires_review: true,
      newer_submission_reviewed: false,
      reviewed: false,
      review_dismissed: false
    )
  end

  sig { returns(ActiveRecord::Relation) }
  def reviews_requested
    submissions.where(
      requests_review: true,
      newer_submission_reviewed: false,
      reviewed: false,
      review_dismissed: false
    )
  end

  sig { returns(ActiveRecord::Relation) }
  def submissions_to_review
    submissions.where('(requests_review OR requires_review) AND NOT reviewed AND NOT newer_submission_reviewed AND NOT review_dismissed')
  end

  sig { params(user: User).returns(T::Boolean) }
  def certificate_downloadable_for?(user)
    user.administrator? ||
    user.teacher?(organization) || (
      !user.guest? &&
       certificate_downloadable &&
       (certificate_unlock_spec.nil? ||
        UnlockSpec.new(self, ActiveSupport::JSON.decode(certificate_unlock_spec)).permits_unlock_for?(user)))
  end

  sig { void }
  def toggle_submission_result_visiblity
    self.hide_submission_results = !hide_submission_results
    save!
  end

  # Returns a hash of exercise group => {
  #   :available_points => number of available points,
  #   :points_by_user => {user_id => number_of_points}
  # }
  sig { returns(T::Hash[String, T::Hash[Symbol, T.untyped]]) }
  def exercise_group_completion_by_user
    # TODO: clean up exercise group discovery

    groups = exercises
             .where(disabled_status: 0)
             .filter_map { |e| e.name if e._fast_visible? }
             .map { |name| name =~ /^(.+)-[^-]+$/ ? T.must(Regexp.last_match(1)) : '' }
             .uniq

    result = T.let({}, T::Hash[String, T::Hash[Symbol, T.untyped]])
    for group in groups
      conn = ActiveRecord::Base.connection

      available_points = ExerciseGroup.new(self, group).available_point_names
      next if available_points.empty?

      sql = <<-EOS
        SELECT user_id, COUNT(*)
        FROM awarded_points
        WHERE course_id = #{conn.quote(id)} AND
              name IN (#{available_points.map { |ap| conn.quote(ap) }.join(',')})
        GROUP BY user_id
      EOS
      by_user = Hash[conn.select_rows(sql).map! { |uid, count| [uid.to_i, count.to_i] }]

      result[group] = {
        available_points: available_points.size,
        points_by_user: by_user
      }
    end
    result
  end

  # Returns a hash of exercise group => {
  #  { awarded: double, late: double }
  # }
  sig { params(user: User).returns(T::Hash[String, T::Hash[Symbol, Numeric]]) }
  def exercise_group_completion_counts_for_user(user)
    # TODO: clean up exercise group discovery

    groups = exercises.enabled.map(&:name).map { |name| name =~ /^(.+)-[^-]+$/ ? T.must(Regexp.last_match(1)) : '' }.uniq.sort

    conn = ActiveRecord::Base.connection
    groups.each_with_object(T.let({}, T::Hash[String, T::Hash[Symbol, Numeric]])) do |group, result|
      available_points = ExerciseGroup.new(self, group).available_point_names
      next if available_points.empty?

      sql = <<-EOS
        SELECT awarded_after_soft_deadline, COUNT(*)
        FROM awarded_points
        WHERE course_id = #{conn.quote(id)} AND
              name IN (#{available_points.map { |ap| conn.quote(ap) }.join(',')}) AND
              user_id = #{conn.quote(user.id)}
        GROUP BY awarded_after_soft_deadline
      EOS

      res = conn.execute(sql).values.to_h
      awarded = res[false].nil? ? 0 : res[false].to_i
      late = res[true].nil? ? 0 : res[true].to_i
      calculated_ratio = (awarded + (late * self.soft_deadline_point_multiplier)).to_f / available_points.length
      result[group] = {
        awarded: awarded,
        late: late,
        available_points: available_points.length,
        progress: calculated_ratio.floor(2)
      }
    end
  end

  sig { returns(T::Boolean) }
  def refreshed?
    !refreshed_at.nil?
  end

  sig { params(user: User).returns(T::Boolean) }
  def taught_by?(user)
    user.teacher?(organization)
  end

  sig { params(user: User).returns(T::Boolean) }
  def assistant?(user)
    assistants.exists?(user.id)
  end

  sig { returns(T::Boolean) }
  def contains_unlock_deadlines?
    exercise_groups.any?(&:contains_unlock_deadlines?)
  end

  sig { params(material: T.nilable(String)).void }
  def material_url=(material)
    if material.blank?
      super('')
    elsif !/^https?:\/\//.match?(material)
      super("http://#{material}")
    else
      super(material)
    end
  end

  sig { returns(T::Boolean) }
  def custom?
    course_template_obj.dummy?
  end

  sig { params(url: T.nilable(String)).void }
  def external_scoreboard_url=(url)
    if /^(https?:\/\/|$)/.match?(url)
      super(url)
    else
      super("http://#{url}")
    end
  end

  sig { returns(T::Boolean) }
  def has_external_scoreboard_url?
    external_scoreboard_url.present?
  end

  sig { params(organization: Organization, course: Course, user: User).returns(String) }
  def parsed_external_scoreboard_url(organization, course, user)
    format(T.must(external_scoreboard_url), user: user.username, course: course.id.to_s, org: organization.slug)
  end

  private
    sig { void }
    def set_cached_version
      self.cached_version = course_template_obj.cached_version
    end

    sig { void }
    def save_template
      course_template_obj.save!
    rescue StandardError => e
      course_template_obj.errors.full_messages.each do |msg|
        errors.add(:base, msg + e.message)
      end
    end

    sig { returns(CourseTemplate) }
    def course_template_obj
      self.course_template ||= CourseTemplate.new_dummy(self)
    end

    sig { void }
    def check_name_length
      name = self.name
      slug = organization&.slug
      # If name starts with organization slug (org-course1), then check that
      # the actual name (course1) is within range (for backward compatibility).
      test_range = if name && slug && name.start_with?("#{slug}-")
        name_range_with_slug(slug)
      else
        name_range
      end

      unless name && test_range.include?(name.length)
        errors.add(:name, "must be between #{name_range} characters")
      end
    end

    sig { returns(T::Range[Integer]) }
    def name_range
      1..40
    end

    sig { params(slug: String).returns(T::Range[Integer]) }
    def name_range_with_slug(slug)
      add_length = slug.length + 1
      (name_range.first + add_length)..(name_range.last + add_length)
    end

    sig { void }
    def check_external_scoreboard_url
      format(T.must(external_scoreboard_url), user: '', course: '', org: '') if external_scoreboard_url.present?
    rescue StandardError
      errors.add(:external_scoreboard_url, 'contains invalid keys')
    end
end
