class User < ActiveRecord::Base
  include Comparable

  has_many :submissions, :dependent => :delete_all
  has_many :awarded_points, :dependent => :delete_all
  has_one :password_reset_key, :dependent => :delete
  has_many :user_field_values, :dependent => :delete_all, :autosave => true
  has_many :student_events, :dependent => :delete_all

  validates :login, :presence     => true,
                    :uniqueness   => true,
                    :length       => { :within => 2..20 }

  validates :email, :presence => true,
                    :uniqueness => true

  attr_accessor :password
  before_save :encrypt_password

  scope :course_students, lambda { |course|
    joins(:submissions).
    where(:submissions => { :course_id => course.id }).
    group('users.id')
  }

  scope :course_sheet_students, lambda { |course, sheetname|
    joins(:awarded_points).
    where(:awarded_points => { :course_id => course.id }).
    joins(:submissions).
    joins("join exercises on submissions.exercise_name = exercises.name").
    where(:exercises => {:gdocs_sheet => sheetname.to_s}).
    group("users.id")
  }

  def field_value(field)
    field_value_record(field).value
  end

  def field_value_record(field)
    value = self.user_field_values.select {|v| v.field_name == field.name }.first
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
