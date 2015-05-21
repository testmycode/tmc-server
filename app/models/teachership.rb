class Teachership < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  validates :user, presence: { message: 'does not exist' }
  validates :organization, presence: true
  validates_uniqueness_of :user_id,
                          scope: [:organization_id],
                          message: 'is already in this organization'
end
