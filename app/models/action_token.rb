require 'securerandom'

# Each user may have 0..1 action tokens in each category.
#
# The password reset key may be generated and sent by e-mail and
# may be used once to set a new password.
# A password reset key is valid for a limited time and may safely be left unused.
#
# The email confirmation token will be created in three situations: 1) sign up,
# 2) old user who first time logs in after this feature was taken to production,
# 3) user chainges to new email address.
# Same token will be used as long as user validates email by clicking validation link.
# After validation token is destroyed.
class ActionToken < ActiveRecord::Base
  belongs_to :user
  validates :user_id, presence: true, uniqueness: { scope: :action }
  validates :token, uniqueness: true # this going wrong should be extremely unlikely

  before_create :randomize_token

  enum action: [:confirm_email, :reset_password]

  def self.generate_password_reset_key_for(user)
    old_key = user.password_reset_key
    old_key.destroy if old_key

    key = self.create!(user: user, action: :reset_password, expires_at: Time.now + 24.hours)
    user.action_tokens << key
    key
  end

  def self.generate_email_confirmation_token(user)
    token = user.email_confirmation_token
    if token.nil?
      token = self.create!(user: user, action: :confirm_email)
      user.action_tokens << token
    end
    token
  end

  def expired?
    expires_at < Time.now
  end

  private

  def randomize_token
    self.token = SecureRandom.urlsafe_base64
  end
end
