# typed: strict
# frozen_string_literal: true

class Assistantship < ApplicationRecord
  extend T::Sig

  belongs_to :user
  belongs_to :course

  validates :user,
            presence: { message: 'does not exist' },
            uniqueness: { scope: :course, message: 'is already an assistant for this course' }
  validates :course, presence: true

  after_save :revoke_handoff_tokens, if: :saved_change_to_user_id?

  private
    sig { void }
    def revoke_handoff_tokens
      AccessTokenAuthentication.revoke_handoff_tokens(T.must(user))
    end
end
