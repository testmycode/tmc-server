class Teachership < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  validates :user, presence: { message: 'does not exist' }
  validates :organization, presence: true
  validates :user, uniqueness: { scope: :organization, message: 'is already in this organization' }
end
