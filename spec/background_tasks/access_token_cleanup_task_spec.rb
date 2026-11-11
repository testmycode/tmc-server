# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe AccessTokenCleanupTask do
  let(:user) { FactoryBot.create(:user) }

  def create_token(**attributes)
    Doorkeeper::AccessToken.create!(resource_owner_id: user.id, scopes: 'public', **attributes)
  end

  it 'deletes tokens that expired or were revoked over the retention period ago' do
    long_expired = create_token(expires_in: 86_400, created_at: 32.days.ago)
    long_revoked = create_token(revoked_at: 31.days.ago)
    recently_expired = create_token(expires_in: 86_400, created_at: 29.days.ago)
    recently_revoked = create_token(revoked_at: 29.days.ago)
    valid = create_token(expires_in: 86_400)
    non_expiring = create_token(created_at: 1.year.ago)

    described_class.new.run

    remaining = Doorkeeper::AccessToken.where(id: [long_expired, long_revoked, recently_expired, recently_revoked, valid, non_expiring].map(&:id))
    expect(remaining).to contain_exactly(recently_expired, recently_revoked, valid, non_expiring)
  end
end
