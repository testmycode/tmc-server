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
  validate :valid_slug?, on: :create

  has_many :teacherships, dependent: :destroy
  has_many :users, through: :teacherships

  scope :accepted_organizations, -> { where(acceptance_pending: false) }
  scope :pending_organizations, -> { where(acceptance_pending: true) }

  def self.init(params, initial_user)
    organization = Organization.new(params.merge(acceptance_pending: true))
    teachership = Teachership.new(user: initial_user, organization: organization)
    if !organization.save || !teachership.save
      organization.destroy
      teachership.destroy
    end
    organization
  end

  def teachers
    users
  end

  def teacher?(user)
    teachers.include? user
  end

  def to_param
    slug
  end

  def find_by_slug(slug)
    Organization.where(slug: slug)
  end

  def valid_slug? # slug must not be an existing route (/org/new etc)
    errors.add(:slug, 'is a system reserved word') if
      %w(new list_requests).include? slug
  end
end
