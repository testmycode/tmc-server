require 'securerandom'

# Each user may have 0..1 password reset keys.
#
# The password reset key may be generated and sent by e-mail and
# may be used once to set a new password.
# A password reset key is valid for a limited time and may safely be left unused.
class PasswordResetKey < ActiveRecord::Base
  belongs_to :user
  validates :user_id, :presence => true, :uniqueness => true
  validates :code, :uniqueness => true  # this going wrong should be extremely unlikely

  before_create :randomize_code

  def self.generate_for(user)
    old_key = user.password_reset_key
    old_key.destroy if old_key

    key = self.create!(:user => user)
    user.password_reset_key = key
    key
  end

  def expired?
    self.created_at < Time.now - 24.hours
  end

private
  def randomize_code
    self.code = SecureRandom.hex(32)
  end
end
