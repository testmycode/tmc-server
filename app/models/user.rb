class User < ActiveRecord::Base
  include Comparable

  has_many :submissions, dependent: :delete_all
  has_many :awarded_points, dependent: :delete_all
  has_many :action_tokens, dependent: :delete_all
  has_many :user_field_values, dependent: :delete_all, autosave: true
  has_many :unlocks, dependent: :delete_all
  has_many :uncomputed_unlocks, dependent: :delete_all
  has_many :reviews, foreign_key: :reviewer_id, inverse_of: :reviewer, dependent: :nullify
  has_many :course_notifications
  has_many :comments
  has_many :certificates
  has_many :teacherships, dependent: :destroy
  has_many :organizations, through: :teacherships
  has_many :assistantships, dependent: :destroy
  has_many :assisted_courses, through: :assistantships, source: :course

  validates :login, presence: true,
                    uniqueness: true,
                    length: { within: 2..20 }

  validates :email, presence: true,
                    uniqueness: true

  scope :legitimate_students, -> { where(legitimate_student: true) }
  scope :non_legitimate_students, -> { where(legitimate_student: false) }

  attr_accessor :password
  before_save :encrypt_password

  def self.course_students(course)
    joins(:awarded_points)
      .where(awarded_points: { course_id: course.id })
      .group('users.id')
  end

  # TODO: Later after enrollment has implemented, this should use it instead
  def self.organization_students(organization)
    joins(awarded_points: :course)
      .where(courses: { organization_id: organization.id })
      .group('users.id')
  end

  def self.course_sheet_students(course, sheetname)
    AwardedPoint.users_in_course_with_sheet(course, sheetname)
  end

  def username
    login # 'login' is a legacy name that ought to be refactored out some day
  end

  def username=(name)
    self.login = name
  end

  # May eventually be separate from username
  def display_name
    username
  end

  def field_value(field)
    field_value_record(field).value
  end

  def field_ruby_value(field)
    field_value_record(field).ruby_value
  end

  def field_value_record(field)
    value = user_field_values.to_a.select { |v| v.field_name == field.name }.first
    unless value
      value = UserFieldValue.new(field_name: field.name, user_id: id, value: '')
      user_field_values << value
    end
    value
  end

  def self.filter_by(filter_params)
    users = includes(:user_field_values)

    users = users.where(administrator: false) unless filter_params['include_administrators']

    for field in UserField.all
      unless filter_params[field.name].blank?
        expected_value =
          case field.field_type
          when :boolean
            '1'
          else
            filter_params[field.name]
          end
        users = users.where(
          'EXISTS (SELECT 1 FROM user_field_values WHERE user_id = users.id AND field_name = ? AND value = ?)',
          field.name,
          expected_value
        )
      end
    end
    users
  end

  def guest?
    false
  end

  def has_password?(submitted_password)
    password_hash == encrypt(submitted_password)
  end

  def self.authenticate(login, submitted_password)
    user = find_by_login(login)
    return nil if user.nil?
    return user if user.has_password?(submitted_password)
  end

  def password_reset_key
    self.action_tokens.find { |t| t.action == 'reset_password' }
  end

  def has_point?(course, point_name)
    awarded_points.where(course_id: course.id, name: point_name).any?
  end

  def has_points?(course, point_names)
    existing = awarded_points.where(course_id: course.id, name: point_names).map(&:name)
    point_names.all? { |pt| existing.include?(pt) }
  end

  def <=>(other)
    login.downcase <=> other.login.downcase
  end

  def teacher?(organization)
    organizations.include? organization
  end

  def teachership(organization)
    Teachership.find_by(user_id: self, organization_id: organization)
  end

  def assistant?(course)
    assisted_courses.exists?(course)
  end

  # TODO: this might need optimizing for minimizing sql queries made
  def readable_by?(user)
    user.administrator? ||
      id == user.id ||
      visible_to_teacher?(user) ||
      visible_to_assistant?(user)
  end

  def visible_to_teacher?(teacher)
    courses = Course.joins(organization: :teacherships).where(teacherships: { user_id: teacher.id })
    courses.each do |c|
      return true if self.student_in_course?(c)
    end
    false
  end

  def visible_to_assistant?(assistant)
    assistant.assisted_courses.each do |c|
      return true if self.student_in_course?(c)
    end
    false
  end

  def student_in_course?(c)
    self.in?(User.course_students(c))
  end

  def student_in_organization?(organization)
    organization.courses.each do |c|
      return true if self.student_in_course?(c)
    end
    false
  end

  def teaching_in_courses
    if !assistantships.empty?
      Course.where(id: assistantships.pluck(:course_id)).ids
    elsif !organizations.empty?
      Course.where(organization_id: teaching_in_organizations).ids
    end
  end

  def teaching_in_organizations
    Teachership.where(user: self).pluck(:organization_id)
  end

  def assistantship(course)
    Assistantship.find_by(user_id: self, course_id: course)
  end

  private

  def encrypt_password
    self.salt = make_salt if new_record?
    self.password_hash = encrypt(password) unless password.blank?
  end

  def encrypt(string)
    secure_hash("#{salt}--#{string}")
  end

  def make_salt
    secure_hash("#{Time.now.utc}--#{password}")
  end

  def secure_hash(string)
    Digest::SHA2.hexdigest(string)
  end
end
