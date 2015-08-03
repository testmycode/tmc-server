class CourseBelongsToOrganization < ActiveRecord::Migration
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
            default_organization.teachers << User.select(&:administrator?)
            default_organization.save!
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
