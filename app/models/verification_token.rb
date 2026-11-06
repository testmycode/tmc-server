# typed: strict
# frozen_string_literal: true

class VerificationToken < ApplicationRecord
  extend T::Sig
  # This class does not use single table inheritance
  self.inheritance_column = :_type_disabled

  belongs_to :user

  enum :type, { email: 0, delete_user: 1 }

  validates :type, presence: true
  validates :user, presence: true

  default_scope { where(created_at: ((Time.current - 1.week)..Time.current)) }

  before_create :generate_token

  private
    sig { returns(String) }
    def generate_token
      self.token = SecureRandom.urlsafe_base64.to_s
    end
end
