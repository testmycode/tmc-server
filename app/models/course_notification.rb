# typed: strict
# frozen_string_literal: true

class CourseNotification < ApplicationRecord
  extend T::Sig

  # These shadow the columns and associations of the same names, so they are never persisted.
  sig { returns(T.nilable(String)) }
  attr_accessor :topic, :message
  sig { returns(T.nilable(User)) }
  attr_accessor :user
  sig { returns(T.nilable(Course)) }
  attr_accessor :course
  belongs_to :course
  belongs_to :user
end
