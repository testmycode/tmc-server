class Teachership < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  validates :user,
            presence: { message: 'does not exist' },
            uniqueness: { scope: :organization, message: 'is already in this organization' }
  validates :organization, presence: true
  validate :not_guest?, on: :create

  def not_guest?
    errors.add(:user, 'cannot be a guest') if user.guest?
  end
end
