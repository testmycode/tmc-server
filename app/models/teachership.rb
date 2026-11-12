# typed: strict
# frozen_string_literal: true

class Teachership < ApplicationRecord
  extend T::Sig

  belongs_to :user
  belongs_to :organization

  validates :user,
            presence: { message: 'does not exist' },
            uniqueness: { scope: :organization, message: 'is already in this organization' }
  validates :organization, presence: true

  after_save :revoke_handoff_tokens, if: :saved_change_to_user_id?

  private
    sig { void }
    def revoke_handoff_tokens
      AccessTokenAuthentication.revoke_handoff_tokens(T.must(user))
    end
end
