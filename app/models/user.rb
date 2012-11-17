class User < ActiveRecord::Base
  include Comparable

  has_many :submissions, :dependent => :delete_all
  has_many :awarded_points, :dependent => :delete_all
  has_one :password_reset_key, :dependent => :delete
  has_many :user_field_values, :dependent => :delete_all, :autosave => true
  has_many :student_events, :dependent => :delete_all
  has_many :unlocks, :dependent => :delete_all
  has_many :reviews, :foreign_key => :reviewer_id, :inverse_of => :reviewer, :dependent => :nullify
  has_many :course_registrations, :dependent => :delete_all
  has_many :courses_registered_to, :through => :course_registrations, :source => :course

  validates :login, :presence     => true,
                    :uniqueness   => true,
                    :length       => { :within => 2..20 }

  validates :email, :presence => true,
                    :uniqueness => true

  attr_accessor :password
  before_save :encrypt_password

  def self.course_students(course)
    joins(:awarded_points).
    where(:awarded_points => { :course_id => course.id }).
    group('users.id')
  end

  def self.course_sheet_students(course, sheetname)
    AwardedPoint.users_in_course_with_sheet(course, sheetname)
  end

  def username
    login  # 'login' is a legacy name that ought to be refactored out some day
  end

  def username=(name)
    self.login = name
  end

  # May eventually be separate from username
  def display_name
    username
  end

  def registered_to_course?(course)
    self.course_registrations.exists?(:course_id => course.id)
  end

  def field_value(field)
    field_value_record(field).value
  end

  def field_ruby_value(field)
    field_value_record(field).ruby_value
  end

  def field_value_record(field)
    value = self.user_field_values.to_a.select {|v| v.field_name == field.name }.first
    if !value
      value = UserFieldValue.new(:field_name => field.name, :user_id => self.id, :value => '')
      self.user_field_values << value
    end
    value
  end

  def self.filter_by(filter_params)
    users = self.includes(:user_field_values)

    users = users.where(:administrator => false) unless filter_params['include_administrators']

    for field in UserField.all
      if !filter_params[field.name].blank?
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
    return nil  if user.nil?
    return user if user.has_password?(submitted_password)
  end

  def has_point?(course, point_name)
    self.awarded_points.where(:course_id => course.id, :name => point_name).any?
  end

  def has_points?(course, point_names)
    existing = self.awarded_points.where(:course_id => course.id, :name => point_names).map(&:name)
    point_names.all? {|pt| existing.include?(pt) }
  end

  def <=>(other)
    self.login.downcase <=> other.login.downcase
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
