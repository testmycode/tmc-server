
# Stores whether and when an exercise has been unlocked for an user.
#
# An exercise is considered unlocked for a user if an unlock for
# (user, course, exercise, valid_after < Time.now) exists.
# The set of unlocks for a (course, user) is recomputed in the following cases:
# - the course is refreshed (since the specs might change)
# - the user has a submission graded
#
# However, if the course has deadlines based on the unlock times of exercises,
# we require the user to explicitly unlock the next set of exercises to avoid
# starting the timer prematurely.
#
class Unlock < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :exercise, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "exercises.course_id = #{self.course_id}" }
  # the DB validates uniqueness for (user_id, course_id, :exercise_name)

  def self.refresh_unlocks(course, user)
    Unlock.transaction do
      unlocks = course.unlocks.where(:user_id => user.id)
      by_exercise_name = Hash[unlocks.map {|u| [u.exercise_name, u]}]
      refresh_unlocks_impl(course, user, by_exercise_name)
      UncomputedUnlock.where(:course_id => course.id, :user_id => user.id).delete_all
    end
  end

  def self.unlock_exercises(exercises, user)
    Unlock.transaction do
      for ex in exercises
        # We assume the unlocks don't yet exist and fail with a uniqueness error if they do
        Unlock.create!(
          :user => user,
          :course_id => ex.course_id,
          :exercise_name => ex.name,
          :valid_after => ex.unlock_spec_obj.valid_after
        )
      end
    end
  end

private

  def self.refresh_unlocks_impl(course, user, user_unlocks_by_exercise_name)
    for exercise in course.exercises
      existing = user_unlocks_by_exercise_name[exercise.name]
      exists = !!existing
      may_exist = exercise.requires_unlock? && exercise.unlock_spec_obj.permits_unlock_for?(user)
      if !exists && may_exist && !exercise.requires_explicit_unlock?
        Unlock.create!(
          :user => user,
          :course => course,
          :exercise => exercise,
          :valid_after => exercise.unlock_spec_obj.valid_after
        )
      elsif exists && !may_exist
        user_unlocks_by_exercise_name[exercise.name].destroy
      elsif exists && may_exist && exercise.unlock_spec_obj.valid_after != existing.valid_after
        existing.valid_after = exercise.unlock_spec_obj.valid_after
        existing.save!
      end
    end
  end
end
