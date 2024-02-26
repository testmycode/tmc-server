# frozen_string_literal: true

class BannedEmail < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Returns true if the given email is banned. Handles emails with +prefiexes by removing the prefix and checking if that address is banned.
  def self.banned?(email)
    email = email.strip
    email = email.gsub(/\+.*@/, '@').downcase
    BannedEmail.exists?(email: email)
  end
end
