class ChangeOrganizationAcceptionToVerify < ActiveRecord::Migration

  class Organization < ActiveRecord::Base
  end

  def self.up

    Organization.all.each do |o|
      o.acceptance_pending = !o.acceptance_pending
      o.save!
    end

    change_table :organizations do |o|
      o.rename :accepted_at, :verified_at
      o.rename :acceptance_pending, :verified

      o.rename :rejected, :disabled
      o.rename :rejected_reason, :disabled_reason

      o.rename :requester_id, :creator_id
    end

  end

  def self.down

    Organization.all.each do |o|
      o.verified = !o.verified
      o.save!
    end

    change_table :organizations do |o|
      o.rename :verified_at, :accepted_at
      o.rename :verified, :acceptance_pending

      o.rename :disabled, :rejected
      o.rename :disabled_reason, :rejected_reason

      o.rename :creator_id, :requester_id
    end

  end
end
