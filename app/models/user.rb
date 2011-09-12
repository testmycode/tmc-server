class User < ActiveRecord::Base
  include Comparable

  has_many :submissions, :dependent => :destroy
  has_many :awarded_points, :dependent => :destroy

  validates :login, :presence     => true,
                    :confirmation => true,
                    :uniqueness   => true,
                    :length       => { :within => 2..20 }

  attr_accessor :password
  validate :check_password
  before_save :encrypt_password

  scope :course_students, lambda { |course|
    joins(:submissions).
    where(:submissions => { :course_id => course.id }).
    group("users.id")
  }

  scope :course_sheet_students, lambda { |course, sheetname|
    joins(:awarded_points).
    where(:awarded_points => { :course_id => course.id }).
    joins(:submissions).
    joins("join exercises on submissions.exercise_name = exercises.name").
    where("exercises.gdocs_sheet IS ?", sheetname).
    group("users.id")
  }

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
    self.login <=> other.login
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

  def check_password
    unless password.blank?
      errors[:password] << "too short" if password.length < 5
    end
  end
end
