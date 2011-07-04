class User < ActiveRecord::Base

#User db has attributes login, password and salt, all String. Login and session  are using this file.

  validates :login, :presence     => true,
                    :confirmation => true,
                    :length       => { :within => 2..20 }

  validates :password, :presence     => true,
                       :confirmation => true,
                       :length       => { :within => 6..40 }

  before_save :encrypt_password

  def has_password?(submitted_password)
    password == encrypt(submitted_password)
  end

  def self.authenticate(login, submitted_password)
    user = find_by_login(login)
    return nil  if user.nil?
    return user if user.has_password?(submitted_password)
  end

  private

  def encrypt_password
    self.salt = make_salt if new_record?
    self.password = encrypt(password)
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
