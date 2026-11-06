# typed: strict
# frozen_string_literal: true

# A transient object representing a non-logged-in user (null object pattern).
#
# The guest is never explicitly saved in the database.
class Guest < User
  extend T::Sig
  before_save :reject_save

  sig { params(args: T.untyped).void }
  def initialize(*args)
    super
    self.login = 'guest'
  end

  sig { returns(T::Boolean) }
  def guest?
    true
  end

  private
    sig { returns(T.noreturn) }
    def reject_save
      raise 'The guest user cannot be saved!'
    end
end
