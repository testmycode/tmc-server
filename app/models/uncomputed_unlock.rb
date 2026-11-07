# typed: strict
# frozen_string_literal: true

# Keeps track of whether a (course, user)'s unlocks have yet to be computed, enabling lazy computation.
# A course refresh populates this table and the UnlockComputerTask background task
# consumes it by calling Unlock.refresh_unlocks on the entries. Code that needs
# up-to-date unlocks should call UncomputedUnlock.resolve for the (course, user) first.
class UncomputedUnlock < ApplicationRecord
  extend T::Sig
  belongs_to :course
  belongs_to :user

  sig { params(course: Course).void }
  def self.create_all_for_course(course)
    transaction do
      course_users = User.course_students(course).pluck(:id)
      existing_users = Set.new(UncomputedUnlock.where(course_id: course.id, user_id: course_users).pluck(:user_id))
      new_users = Set.new(course_users).difference(existing_users)

      rows_to_insert = new_users.map { |uid| { course_id: course.id, user_id: uid } }
      # The obvious race condition here may result in a duplicate being inserted.
      # This is fine since Unlock.refresh_unlocks does a corresponding delete_all.
      UncomputedUnlock.create!(rows_to_insert)
    end
  end

  # Primarily used for demoing unlock date change through gui, this version of the method creates uncomputed unlocks
  # for every user, not requiring the user to have awarded points from the course. This method will most likely be
  # left unused in production build.
  sig { params(course: Course).void }
  def self.create_all_for_course_eager(course)
    transaction do
      rows_to_insert = User.pluck(:id).map { |uid| { course_id: course.id, user_id: uid } }
      UncomputedUnlock.create!(rows_to_insert)
    end
  end

  sig { params(course: Course, user: User).void }
  def self.resolve(course, user)
    if find_by(course_id: course, user_id: user)
      Unlock.refresh_unlocks(course, user)
    end
  end
end
