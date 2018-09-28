# frozen_string_literal: true

# A transient object representing a non-logged-in user (null object pattern).
#
# The guest is never explicitly saved in the database.
class Guest < User
  before_save :reject_save

  def initialize(*args)
    super(*args)
    self.login = 'guest'
  end

  def guest?
    true
  end

  private

  def reject_save
    raise 'The guest user cannot be saved!'
  end
end
