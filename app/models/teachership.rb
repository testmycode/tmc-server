class Teachership < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  validates :user,
            presence: { message: 'does not exist' },
            uniqueness: { scope: :organization, message: 'is already in this organization' }
  validates :organization, presence: true
end
