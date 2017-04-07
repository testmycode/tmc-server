# Organisations (schools etc.) have teachers and their own customized courses.

class Organization < ActiveRecord::Base
  include Swagger::Blocks
  
  swagger_schema :Organization do
    key :required, [:name, :information, :slug, :logo_path, :pinned]

    property :name, type: :string, example: 'University of Helsinki'
    property :information, type: :string, example: 'Organization for University of Helsinki'
    property :slug, type: :string, example: 'hy'
    property :logo_path, type: :string, example: '/logos/hy_logo.png'
    property :pinned, type: :boolean, example: false
  end

  validates :name,
            presence: true,
            length: { within: 2..40 },
            uniqueness: true
  validates :information, length: { maximum: 255 }
  validates :slug,
            presence: true,
            length: { within: 2..20 },
            format: {
              with: /\A[a-z0-9\-_]+\z/,
              message: 'must be lowercase alphanumeric and may contain underscores and hyphens'
            },
            uniqueness: true
  validates :verified, inclusion: [true, false]
  validate :valid_slug?, on: :create

  has_many :teacherships, dependent: :destroy
  has_many :teachers, through: :teacherships, source: :user
  has_many :courses, dependent: :nullify

  belongs_to :creator, class_name: 'User'

  has_attached_file :logo, styles: { small_logo: '100x100>' }
  validates_attachment_content_type :logo, content_type: /\Aimage\/.*\Z/

  scope :accepted_organizations, -> { where(verified: true).where(disabled: false)}
  scope :pending_organizations, -> { where(verified: false).where(disabled: false) }
  scope :assisted_organizations, ->(user) { joins(:courses, courses: :assistantships).where(assistantships: { user_id: user.id }) }
  scope :taught_organizations, ->(user) { joins(:teacherships).where(teacherships: { user_id: user.id }) }
  scope :participated_organizations, ->(user) { joins(:courses, courses: :awarded_points).where(awarded_points: { user_id: user.id }) }
  scope :visible_organizations, -> { accepted_organizations.where(hidden: false) }

  def self.init(params, initial_user)
    organization = Organization.new(params.merge(verified: false, creator: initial_user))
    teachership = Teachership.new(user: initial_user, organization: organization)
    if !organization.save || !teachership.save
      organization.destroy
      teachership.destroy
    end
    organization
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
    errors.add(:slug, 'is a system reserved word') if %w(new list_requests).include? slug
  end
end
