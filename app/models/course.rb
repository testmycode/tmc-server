require 'gdocs_export'
require 'course_refresher'
require 'system_commands'
require 'date_and_time_utils'

class Course < ActiveRecord::Base
  include SystemCommands
  include Swagger::Blocks

  swagger_schema :Course do
    key :required, [ :name, :hide_after, :hidden, :cache_version, :spreadsheet_key, :hidden_if_registered_after,
                     :refreshed_at, :locked_exercise_points_visible, :description, :paste_visibility, :formal_name,
                     :certificate_downloadable, :certificate_unlock_spec, :organization_id, :disabled_status,
                     :title, :material_url, :course_template_id, :hide_submission_results, :external_scoreboard_url,]

    property :name, type: :string, example: "organizationid-coursename"
    property :hide_after, type: :string, example: "2016-10-10T13:22:19.554+03:00"
    property :hidden, type: :boolean, example: false
    property :cache_version, type: :integer, example: 1
    property :spreadsheet_key, type: :string
    property :hidden_if_registered_after, type: :string
    property :refreshed_at, type: :string, example: "2016-10-10T13:22:36.871+03:00"
    property :locked_exercise_points_visible, type: :boolean, example: true
    property :description, type: :string, example: ""
    property :paste_visibility, type: :string
    property :formal_name, type: :string
    property :certificate_downloadable, type: :boolean, example: false
    property :certificate_unlock_spec, type: :string
    property :organization_id, type: :integer, example: 1
    property :disabled_status, type: :string, example: "enabled"
    property :title, type: :string, example: "testcourse"
    property :material_url, type: :string, example: ""
    property :course_template_id, type: :integer, example: 1
    property :hide_submission_results, type: :boolean, example: false
    property :external_scoreboard_url, type: :string
    property :organization_slug, type: :string, example: "hy"
  end

  swagger_schema :CoreCourseDetails do
    key :required, [ :id, :name, :title, :description, :details_url, :unlock_url, :reviews_url, :comet_url, :spyware_urls, :unlockables, :exercises, ]

    property :id, type: :integer, example: 13
    property :name, type: :string, example: "organizationid-coursename"
    property :title, type: :string, example: "coursetitle"
    property :description, type: :string, example: "description of the course"
    property :details_url, type: :string, example: "http://tmc.mooc.fi/api/v8/core/courses/13"
    property :unlock_url, type: :string, example: "https://tmc.mooc.fi/api/v8/core/courses/13/unlock"
    property :reviews_url, type: :string, example: "https://tmc.mooc.fi/api/v8/core/courses/13/reviews"
    property :comet_url, type: :string, example: "https://tmc.mooc.fi:8443/comet"
    property :spyware_urls, type: :array do
      items do
        key :type, :string
        key :example, "http://mooc.spyware.testmycode.net/"
      end
    end
    property :unlockables, type: :array do
      items do
        key :type, :string
        key :example, ""
      end
    end
    property :exercises, type: :array do
      items do
        key :'$ref', :CoreExerciseDetails
      end
    end
  end

  def course_as_json
    as_json(only: [
        :name,
        :hide_after,
        :hidden,
        :cache_version,
        :spreadsheet_key,
        :hidden_if_registered_after,
        :refreshed_at,
        :locked_exercise_points_visible,
        :description,
        :paste_visibility,
        :formal_name,
        :certificate_downloadable,
        :certificate_unlock_spec,
        :organization_id,
        :disabled_status,
        :title,
        :descrpition,
        :material_url,
        :course_template_id,
        :hide_submission_results,
        :external_scoreboard_url,
    ],
    methods: :organization_slug)
  end

  swagger_schema :CourseLinks do
    key :required, [ :id, :name, :title, :description, :details_url, :unlock_url, :reviews_url, :comet_url, :spyware_urls ]

    property :id, type: :integer, example: 13
    property :name, type: :string, example: "organizationid-coursename"
    property :title, type: :string, example: "coursetitle"
    property :description, type: :string, example: "description of the course"
    property :details_url, type: :string, example: "https://tmc.mooc.fi/api/v8/core/courses/13"
    property :unlock_url, type: :string, example: "https://tmc.mooc.fi/api/v8/core/courses/13/unlock"
    property :reviews_url, type: :string, example: "https://tmc.mooc.fi/api/v8/core/courses/13/reviews"
    property :comet_url, type: :string, example: "https://tmc.mooc.fi:8443/comet"
    property :spyware_urls, type: :array do
      items do
        key :type, :string
        key :example, "http://mooc.spyware.testmycode.net/"
      end
    end
  end

  def links_as_json(view_context)
    {
        id: self.id,
        name: self.name,
        title: self.title,
        description: self.description,
        details_url: view_context.api_v8_core_course_url(self),
        unlock_url: view_context.api_v8_core_course_unlock_url(self),
        reviews_url: view_context.api_v8_core_course_reviews_url(self),
        comet_url: CometServer.get.client_url,
        spyware_urls: SiteSetting.value('spyware_servers'),
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

  # If made from template, make sure cache_version is not out of sync.
  before_save :set_cache_version
  before_validation :save_template
  validates :source_url, presence: true
  #validates :custom_points_url,
  #          format: {
  #            with: /(\Ahttps?:\/\/|\A\z|^$)/,
  #            message: 'should begin with http:// or https://'
  #          }
  validate :check_external_scoreboard_url

  has_many :exercises, dependent: :delete_all
  has_many :submissions, dependent: :delete_all
  has_many :users, -> { uniq }, through: :submissions
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

  enum disabled_status: [ :enabled, :disabled ]

  def destroy
    # Optimization: delete dependent objects quickly.
    # Rails' :dependent => :delete_all is very slow.
    # Even self.association.delete_all first does a SELECT.
    # This relies on the database to cascade deletes.
    ActiveRecord::Base.connection.execute("DELETE FROM courses WHERE id = #{id}")
    assistantships.each { |a| a.destroy! } # apparently this is not performed automatically with optimized destroy

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

  def self.new_from_template(course_template)
    Course.new(name: course_template.name,
               title: course_template.title,
               description: course_template.description,
               material_url: course_template.material_url,
               cache_version: course_template.cache_version,
               course_template: course_template)
  end

  def git_branch
    course_template_obj.git_branch
  end

  def organization_slug
    organization.slug
  end

  def source_url
    course_template_obj.source_url
  end

  def source_backend
    course_template_obj.source_backend
  end

  def git_branch=(branch)
    course_template_obj.git_branch = branch
  end

  def source_url=(url)
    course_template_obj.source_url = url
  end

  def source_backend=(backend)
    course_template_obj.source_backend = backend
  end

  def visible_to?(user)
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

  def hide_after=(x)
    super(DateAndTimeUtils.to_time(x, prefer_end_of_day: true))
  end

  def hidden_if_registered_after=(x)
    super(DateAndTimeUtils.to_time(x, prefer_end_of_day: false))
  end

  # This could eventually be made a hstore
  def options=(new_options)
    if !new_options['hide_after'].blank?
      self.hide_after = new_options['hide_after']
    else
      self.hide_after = nil
    end

    if !new_options['hidden_if_registered_after'].blank?
      self.hidden_if_registered_after = new_options['hidden_if_registered_after']
    else
      self.hidden_if_registered_after = nil
    end

    self.hidden = !!new_options['hidden']
    self.spreadsheet_key = new_options['spreadsheet_key']

    self.paste_visibility = new_options['paste_visibility']
    if !new_options['locked_exercise_points_visible'].nil?
      self.locked_exercise_points_visible = new_options['locked_exercise_points_visible']
    else
      self.locked_exercise_points_visible = true
    end

    if !new_options['formal_name'].blank?
      self.formal_name = new_options['formal_name']
    else
      self.formal_name = nil
    end

    self.certificate_downloadable = !!new_options['certificate_downloadable']

    if !new_options['certificate_unlock_spec'].blank?
      self.certificate_unlock_spec = new_options['certificate_unlock_spec']
    else
      self.certificate_unlock_spec = nil
    end
  end

  def gdocs_sheets(exercises = nil)
    exercises = self.exercises.select { |ex| !ex.hidden? && ex.published? } unless exercises
    exercises.map(&:gdocs_sheet).reject(&:nil?).uniq
  end

  def refresh_gdocs_worksheet(sheetname)
    GDocsExport.refresh_course_worksheet_points self, sheetname
  end

  def self.cache_root
    "#{FileStore.root}/course"
  end

  def increment_cache_version
    course_template_obj.increment_cache_version
  end

  def cache_path
    course_template_obj.cache_path
  end

  # Holds a clone of the course repository
  def clone_path
    "#{cache_path}/clone"
  end

  def git_revision
    Dir.chdir clone_path do
      output = `git rev-parse --verify HEAD`
      if $?.success?
        output.strip
      else
        nil
      end
    end
  rescue
    nil
  end

  def solution_path
    "#{cache_path}/solution"
  end

  def stub_path
    "#{cache_path}/stub"
  end

  def stub_zip_path
    "#{cache_path}/stub_zip"
  end

  def solution_zip_path
    "#{cache_path}/solution_zip"
  end

  def exercise_groups(force_reload = false)
    @groups = nil if force_reload
    @groups ||= begin
      result = exercises.all.map(&:exercise_group_name).uniq
        .map { |gname| ExerciseGroup.new(self, gname) }

      new_parents = []
      begin
        all_parents = result.map(&:parent_name).reject(&:nil?)
        new_parents = all_parents.reject { |pn| result.any? { |eg| eg.name == pn } }.uniq
        result += new_parents.map { |pn| ExerciseGroup.new(self, pn) }
      end until new_parents.empty?

      result.sort
    end
  end

  def exercise_group_by_name(name, force_reload = false)
    exercise_groups(force_reload).find { |eg| eg.name == name }
  end

  # Returns exercises in group `name`, or whose full name is `name`.
  def exercises_by_name_or_group(name, force_reload = false)
    group = exercise_group_by_name(name, force_reload)
    exercises.to_a.select { |ex| ex.name == name || (group && ex.belongs_to_exercise_group?(group)) }
  end

  def unlockable_exercises_for(user)
    UncomputedUnlock.resolve(self, user)
    unlocked = unlocks.where(user_id: user.id).pluck(:exercise_name)
    exercises.to_a.select { |ex| !unlocked.include?(ex.name) && ex.unlockable_for?(user) }
  end

  def reload
    super
    @groups = nil
  end

  def refresh(options = {})
    CourseRefresher.new.refresh_course(self, options)
  end

  def delete_cache
    FileUtils.rm_rf cache_path if custom?
  end

  def self.valid_source_backends
    ['git']
  end

  def self.default_source_backend
    'git'
  end

  def time_of_first_submission
    sub = submissions.order('created_at ASC').limit(1).first
    if sub
      sub.created_at
    else
      nil
    end
  end

  def time_of_last_submission
    sub = submissions.order('created_at DESC').limit(1).first
    if sub
      sub.created_at
    else
      nil
    end
  end

  def reviews_required
    submissions.where(
      requires_review: true,
      newer_submission_reviewed: false,
      reviewed: false,
      review_dismissed: false
    )
  end

  def reviews_requested
    submissions.where(
      requests_review: true,
      newer_submission_reviewed: false,
      reviewed: false,
      review_dismissed: false
    )
  end

  def submissions_to_review
    submissions.where('(requests_review OR requires_review) AND NOT reviewed AND NOT newer_submission_reviewed AND NOT review_dismissed')
  end

  def certificate_downloadable_for?(user)
    user.administrator? || (
      !user.guest? &&
       certificate_downloadable &&
       (certificate_unlock_spec.nil? ||
        UnlockSpec.new(self, ActiveSupport::JSON.decode(certificate_unlock_spec)).permits_unlock_for?(user)))
  end

  def toggle_submission_result_visiblity
    self.hide_submission_results = !self.hide_submission_results
    save!
  end

  # Returns a hash of exercise group => {
  #   :available_points => number of available points,
  #   :points_by_user => {user_id => number_of_points}
  # }
  def exercise_group_completion_by_user
    # TODO: clean up exercise group discovery

    groups = exercises
      .where(disabled_status: 0)
      .select { |e| e._fast_visible? }
      .map(&:name)
      .map { |name| if name =~ /^(.+)-[^-]+$/ then $1 else '' end }
      .uniq

    result = {}
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
  #   :available_points => number of available points,
  #   :points_by_user => {user_id => number_of_points}
  # }
  def exercise_group_completion_ratio_for_user(user)
    # TODO: clean up exercise group discovery

    groups = exercises.map(&:name).map { |name| if name =~ /^(.+)-[^-]+$/ then $1 else '' end }.uniq.sort

    conn = ActiveRecord::Base.connection
    groups.each_with_object({}) do |group, result|
      available_points = ExerciseGroup.new(self, group).available_point_names
      next if available_points.empty?

      sql = <<-EOS
        SELECT COUNT(*)
        FROM awarded_points
        WHERE course_id = #{conn.quote(id)} AND
              name IN (#{available_points.map { |ap| conn.quote(ap) }.join(',')}) AND
              user_id = #{conn.quote(user.id)}
        GROUP BY user_id
      EOS

      res = conn.select_rows(sql)
      result[group] = res.empty? ? 0 : res[0][0].to_f / available_points.length
    end
  end

  def refreshed?
    !refreshed_at.nil?
  end

  def taught_by?(user)
    user.teacher?(organization)
  end

  def assistant?(user)
    assistants.exists?(user.id)
  end

  def contains_unlock_deadlines?
    exercise_groups.any? { |group| group.contains_unlock_deadlines?}
  end

  def material_url=(material)
    return super('') if material.blank?
    unless material =~ /^https?:\/\//
      return super("http://#{material}")
    end
    super(material)
  end

  def custom?
    course_template_obj.dummy?
  end

  def external_scoreboard_url=(url)
    return super("http://#{url}") unless url =~ /^(https?:\/\/|$)/
    super(url)
  end

  def contains_unlock_deadlines?
    exercise_groups.any? { |group| group.contains_unlock_deadlines?}
  end

  def has_external_scoreboard_url?
    !external_scoreboard_url.blank?
  end

  def parsed_external_scoreboard_url(organization, course, user)
    external_scoreboard_url % { user: user.username, course: course.id.to_s, org: organization.slug }
  end

  private

  def set_cache_version
    self.cache_version = course_template_obj.cache_version
  end

  def save_template
    course_template_obj.save!
  rescue => e
    course_template_obj.errors.full_messages.each do |msg|
      errors.add(:base, msg + e.message)
    end
  end

  def course_template_obj
    self.course_template ||= CourseTemplate.new_dummy(self)
  end

  def check_name_length
    # If name starts with organization slug (org-course1), then check that
    # the actual name (course1) is within range (for backward compatibility).
    if !name.nil? && name.start_with?("#{organization.slug}-")
      test_range = name_range_with_slug
    else
      test_range = name_range
    end

    unless (!name.nil? && test_range.include?(name.length))
      errors.add(:name, "must be between #{name_range} characters")
    end
  end

  def name_range
    1..40
  end

  def name_range_with_slug
    add_length = organization.slug.length + 1
    (name_range.first + add_length)..(name_range.last + add_length)
  end

  def check_external_scoreboard_url
    begin
      external_scoreboard_url % { user: '', course: '', org: '' } unless external_scoreboard_url.blank?
    rescue
      errors.add(:external_scoreboard_url, 'contains invalid keys')
    end
  end
end
