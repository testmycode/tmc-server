# frozen_string_literal: true

class UserFieldValue < ApplicationRecord
  include ExtraFieldValue

  belongs_to :user
end
