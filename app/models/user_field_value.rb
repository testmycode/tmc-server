# frozen_string_literal: true

class UserFieldValue < ApplicationController
  include ExtraFieldValue

  belongs_to :user
end
