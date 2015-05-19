class Organization < ActiveRecord::Base
  validates :name,
            presence: true,
            length: { within: 2..40 },
            uniqueness: true
  validates :information, length: { maximum: 500 }
  validates :slug,
            presence: true,
            length: { within: 2..20 },
            format: {
              with: /\A[a-z0-9\-_]+\z/,
              message: 'must be lowercase alphanumeric and may contain underscores and hyphens'
            },
            uniqueness: true
  validates :acceptance_pending, inclusion: [true, false]

  has_many :teacherships
  has_many :users, through: :teacherships

  scope :accepted_organizations, -> { where(acceptance_pending: false) }
  scope :pending_organizations, -> { where(acceptance_pending: true) }

  def self.init(params, initial_user)
    org = Organization.new(params.merge({ acceptance_pending: true }))
    Teachership.create!({ user: initial_user, organization: org })
    return org
  end
end
