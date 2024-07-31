# frozen_string_literal: true

class OrganizationMembership < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  validates :user,
            presence: { message: 'does not exist' },
            uniqueness: { scope: :organization, message: 'is already in this organization' }
  validates :organization, presence: true
end
