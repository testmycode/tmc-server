require 'gdocs_export'
require 'course_refresher'
require 'system_commands'
require 'date_and_time_utils'

class Course < ActiveRecord::Base
  include SystemCommands

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
            length: { within: 1..40 }
  validates :description, length: { maximum: 512 }
  validate :check_name_length

  # If made from template, make sure cache_version is not out of sync.
  before_save :set_cache_version
  before_validation :save_template

  has_many :exercises, dependent: :delete_all
  has_many :submissions, dependent: :delete_all
  has_many :available_points, through: :exercises
  has_many :awarded_points, dependent: :delete_all
  has_many :test_scanner_cache_entries, dependent: :delete_all
  has_many :feedback_questions, dependent: :delete_all
  has_many :feedback_answers # destroyed transitively when questions are destroyed
  has_many :unlocks, dependent: :delete_all
  has_many :uncomputed_unlocks, dependent: :delete_all
  has_many :course_notifications, dependent: :delete_all
  has_many :assistantships, dependent: :destroy
  has_many :assistants, through: :assistantships, source: :user

  belongs_to :organization
  belongs_to :course_template

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

  def exercise_groups
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

  def exercise_group_by_name(name)
    exercise_groups.find { |eg| eg.name == name }
  end

  # Returns exercises in group `name`, or whose full name is `name`.
  def exercises_by_name_or_group(name)
    group = exercise_group_by_name(name)
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

  # Returns a hash of exercise group => {
  #   :available_points => number of available points,
  #   :points_by_user => {user_id => number_of_points}
  # }
  def exercise_group_completion_by_user
    # TODO: clean up exercise group discovery

    groups = exercises.map(&:name).map { |name| if name =~ /^(.+)-[^-]+$/ then $1 else '' end }.uniq

    result = {}
    for group in groups
      conn = ActiveRecord::Base.connection

      # FIXME: this bit is duplicated in MetadataValue in master branch.
      # http://stackoverflow.com/questions/5709887/a-proper-way-to-escape-when-building-like-queries-in-rails-3-activerecord
      pattern = (group.gsub(/[!%_]/) { |x| '!' + x }) + '-%'

      sql = <<-EOS
        SELECT available_points.name
        FROM exercises, available_points
        WHERE exercises.course_id = #{conn.quote(id)} AND
              exercises.name LIKE #{conn.quote(pattern)} AND
              exercises.id = available_points.exercise_id
      EOS
      available_points = conn.select_values(sql)
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

  def refreshed?
    !refreshed_at.nil?
  end

  def taught_by?(user)
    user.teacher?(organization)
  end

  def assistant?(user)
    assistants.exists?(user)
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

  def contains_unlock_deadlines?
    exercise_groups.any? { |group| group.contains_unlock_deadlines?}
  end

  private

  def set_cache_version
    self.cache_version = course_template_obj.cache_version
  end

  def save_template
    course_template_obj.save!
  rescue
    course_template_obj.errors.full_messages.each do |msg|
      errors.add(:base, msg)
    end
  end

  def course_template_obj
    self.course_template ||= CourseTemplate.new_dummy(self)
  end

  def check_name_length
    # If name starts with organization slug (org-course1), then check that
    # the actual name (course1) is within range (for backward compatibility).
    if name.start_with?("#{organization.slug}-")
      test_range = name_range_with_slug
    else
      test_range = name_range
    end

    unless test_range.include?(name.length)
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
end
