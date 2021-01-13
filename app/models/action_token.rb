# frozen_string_literal: true

require 'securerandom'

# Each user may have 0..1 password reset keys.
#
# The password reset key may be generated and sent by e-mail and
# may be used once to set a new password.
# A password reset key is valid for a limited time and may safely be left unused.
class ActionToken < ApplicationRecord
  belongs_to :user
  validates :user_id, presence: true, uniqueness: true
  validates :token, uniqueness: true # this going wrong should be extremely unlikely

  before_create :randomize_token

  enum action: %i[confirm_email reset_password enroll_course]

  def self.generate_password_reset_key_for(user)
    old_key = user.password_reset_key
    old_key&.destroy

    key = create!(user: user, action: :reset_password, expires_at: Time.now + 72.hours)
    user.action_tokens << key
    key
  end

  def expired?
    expires_at < Time.now
  end

  private
    def randomize_token
      self.token = SecureRandom.urlsafe_base64
    end
end
