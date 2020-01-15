# frozen_string_literal: true

class User < ActiveRecord::Base
  include Comparable
  include Gravtastic
  include Swagger::Blocks
  gravtastic

  swagger_schema :UsersBasicInfo do
    key :required, %i[id username email]
    property :id, type: :integer, example: 1
    property :username, type: :string, example: 'student'
    property :email, type: :string, example: 'student@example.com'
    property :administrator, type: :boolean, example: false
  end

  has_many :submissions, dependent: :delete_all
  has_many :awarded_points, dependent: :delete_all
  has_many :action_tokens, dependent: :delete_all
  has_many :user_field_values, dependent: :delete_all, autosave: true
  has_many :user_app_data, dependent: :delete_all, autosave: true
  has_many :model_solution_token_useds, dependent: :nullify
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
  has_many :verification_tokens

  validates :login, presence: true,
                    uniqueness: { case_sensitive: false },
                    length: { within: 2..50 }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: {
                      with: URI::MailTo::EMAIL_REGEXP,
                      message: 'does not look like an email'
                    }

  validate :reject_common_login_mistakes, on: :create

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
      next if filter_params[field.name].blank?
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
    users
  end

  def guest?
    false
  end

  def has_password?(submitted_password)
    if !salt
      return Argon2::Password.verify_password(submitted_password, argon_hash)
    end
    result = Argon2::Password.verify_password(old_encrypt(submitted_password), argon_hash)
    if result && salt
      self.argon_hash = generate_argon(submitted_password)
      self.salt = nil
      save
    end
    result
  end

  def self.authenticate(login, submitted_password)
    return nil unless login
    login = login.strip
    user = find_by(login: login)
    user ||= find_by('lower(email) = ?', login.downcase)
    return nil if user.nil?
    return user if user.has_password?(submitted_password)
  end

  def password_reset_key
    action_tokens.find { |t| t.action == 'reset_password' }
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
    assisted_courses.exists?(course.id)
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
      return true if student_in_course?(c)
    end
    false
  end

  def visible_to_assistant?(assistant)
    assistant.assisted_courses.each do |c|
      return true if student_in_course?(c)
    end
    false
  end

  def student_in_course?(c)
    in?(User.course_students(c))
  end

  def student_in_organization?(organization)
    organization.courses.each do |c|
      return true if student_in_course?(c)
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

  def courses_with_submissions
    exercises = Exercise.arel_table
    submissions = Submission.arel_table
    sql =
      query = submissions_exercises_and_points_for_user
    without_disabled(query)
    query
      .project(exercises[:course_id], exercises[:name], exercises[:id], submissions[:id].count, Arel::Nodes::SqlLiteral.new('bool_or(submissions.all_tests_passed)').as('all_tests_passed'), Arel::Nodes::SqlLiteral.new('ARRAY_AGG(DISTINCT available_points.name order by available_points.name) = ARRAY_AGG(DISTINCT awarded_points.name order by awarded_points.name)').as('got_all_points'), Arel::Nodes::SqlLiteral.new("STRING_AGG(DISTINCT available_points.name, ' ' order by available_points.name)").as('available_points'), Arel::Nodes::SqlLiteral.new("STRING_AGG(DISTINCT awarded_points.name, ' ' order by awarded_points.name)").as('awarded_points'))
    sql = query.to_sql

    result = {}
    ActiveRecord::Base.connection.execute(sql).each do |record|
      # {"course_id"=>"8", "name"=>"viikkob-B.1.Opiskelijanumero", "count"=>"1", "all_tests_passed"=>"t", "got_all_points"=>"t", "available_points"=>"{B.1}", "awarded_points"=>"{B.1}"}
      course_id = record['course_id'].to_i
      result[course_id] ||= []
      result[course_id] << {
        exercise_name: record['name'],
        exercise_id: record['id'].to_i,
        submissions_count: record['count'].to_i,
        all_tests_passed: record['all_tests_passed'] == 't',
        got_all_points: record['got_all_points'] == 't',
        available_points: record['available_points'].nil? ? nil : record['available_points'].split(' '),
        awarded_points: record['awarded_points'].nil? ? nil : record['awarded_points'].split(' ')
      }
    end
    result.default = []
    result
  end

  def course_ids
    results = []
    ActiveRecord::Base.connection.execute(course_ids_arel.to_sql).each do |record|
      results << record['course_id']
    end
    results
  end

  def generate_password_reset_link
    key = ActionToken.generate_password_reset_key_for(self)
    settings = SiteSetting.value('emails')
    url = settings['baseurl'].sub(/\/+$/, '') + '/reset_password/' + key.token
    url
  end

  def self.search(query)
    return User.none unless query
    User.where('lower(email) LIKE ?', "%#{query.strip.downcase}%")
  end

  private

    def course_ids_arel
      courses = Course.arel_table
      submissions = Submission.arel_table
      submissions.project(submissions[:course_id].as('course_id')).distinct
                 .join(courses).on(submissions[:course_id].eq(courses[:id]))
                 .where(courses[:disabled_status].eq(0))
                 .where(submissions[:user_id].eq(id))
                 .order(submissions[:course_id])
    end

    def without_disabled(query)
      exercises = Exercise.arel_table
      query.where(exercises[:disabled_status].eq(0))
      query.where(exercises[:hidden].eq(false))
    end

    def without_hidden_points(query)
      exercises = Exercise.arel_table
      query.where(exercises[:hide_submission_results].eq(false))
    end

    def submissions_exercises_and_points_for_user
      users = User.arel_table
      awarded_points = AwardedPoint.arel_table
      available_points = AvailablePoint.arel_table
      exercises = Exercise.arel_table
      submissions = Submission.arel_table

      exercises
        .join(users, Arel::Nodes::OuterJoin).on(users[:id].eq(id))
        .join(available_points, Arel::Nodes::OuterJoin).on(available_points[:exercise_id].eq(exercises[:id]))
        .join(submissions, Arel::Nodes::OuterJoin).on(submissions[:exercise_name].eq(exercises[:name]), submissions[:user_id].eq(id), submissions[:course_id].eq(exercises[:course_id]))
        .join(awarded_points, Arel::Nodes::OuterJoin).on(awarded_points[:submission_id].eq(submissions[:id]), awarded_points[:course_id].eq(submissions[:course_id]), awarded_points[:user_id].eq(users[:id]))
        .where(exercises[:course_id].in(course_ids_arel))
        .group(exercises[:name], exercises[:course_id], exercises[:id])
        .order(exercises[:name], exercises[:course_id])
    end

    def encrypt_password
      if password.present?
        self.argon_hash = generate_argon(password)
        self.salt = nil
      end
    end

    def old_encrypt(string)
      secure_hash("#{salt}--#{string}")
    end

    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end

    def reject_common_login_mistakes
      return if login.blank?
      errors.add(:login, 'may not be your email address. Keep in mind that your username is public to everyone.') if login.include?('@')
      errors.add(:login, 'may not be a number. Use the organizational identifier field for your student number.') if login.scan(/\D/).empty?
      errors.add(:email, 'may not end with "@ad.helsinki.fi". You cannot receive any emails with this address -- it\'s only used for your webmail login. Figure out what your real email address is and try again. It is usually of the form firstname.lastname@helsinki.fi but verify this first.') if email.end_with?('@ad.helsinki.fi')
      errors.add(:email, 'is incorrect. You probably meant firstname.lastname@helsinki.fi. Keep in mind that your email address does not contain your University of Helsinki username.') if email.end_with?('@helsinki.fi') && !/.*\..*@helsinki.fi/.match?(email)
    end

    def generate_argon(input)
      Argon2::Password.new(t_cost: 4, m_cost: 15).create(input)
    end
end
