class CourseBelongsToOrganization < ActiveRecord::Migration[4.2]

  class Course < ActiveRecord::Base
    belongs_to :organization, :class_name => 'CourseBelongsToOrganization::Organization'
  end

  class User < ActiveRecord::Base
    has_many :teacherships, dependent: :destroy, class_name: 'CourseBelongsToOrganization::Teachership'
    has_many :organizations, through: :teacherships, class_name: 'CourseBelongsToOrganization::Organization'
  end

  class Teachership < ActiveRecord::Base
    belongs_to :user, :class_name => 'CourseBelongsToOrganization::User'
    belongs_to :organization, :class_name => 'CourseBelongsToOrganization::Organization'
  end

  class Organization < ActiveRecord::Base
    has_many :courses, :class_name => 'CourseBelongsToOrganization::Course'
    has_many :teacherships, class_name: 'CourseBelongsToOrganization::Teachership'
    has_many :teachers, through: :teacherships, source: :user, :class_name => 'CourseBelongsToOrganization::Teacher'
  end

  def change
    add_reference :courses, :organization, index: true, foreign_key: true
    default_organization = Organization.find_by slug: 'default'
    reversible do |dir|
      dir.up do
        orphans = Course.select { |c| c.organization.nil? }
        unless orphans.empty?
          if default_organization.nil?
            default_organization = Organization.create name: 'Default',
              information: 'Temporary organization used for migrating purposes',
              slug: 'default',
              acceptance_pending: false
            User.where(administrator: true) do |u|
              Teachership.create(user: u, organization_id: default_organization);
            end
          end
          orphans.each do |c|
            c.organization = default_organization
            c.save!
          end
        end
      end
      dir.down do
        Course.all.each { |c| c.organization = nil; c.save! }
        default_organization.destroy unless default_organization.nil?
      end
    end
  end
end
