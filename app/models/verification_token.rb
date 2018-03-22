class VerificationToken < ActiveRecord::Base
  # This class does not use single table inheritance
  self.inheritance_column = :_type_disabled

  belongs_to :user

  enum type: [:email]

  validates :type, presence: true
  validates :user, presence: true

  default_scope { where(created_at: ((Time.current - 1.week)..Time.current)) }

  before_create :generate_token

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64.to_s
  end
end
