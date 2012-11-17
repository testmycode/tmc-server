
# An exercise is considered unlocked for a user if an unlock for
# (user, course, exercise, valid_after < Time.now) exists.
# The set of unlocks for a (course, user) is recomputed in the following cases:
# - the course is refreshed (since the specs might change)
# - the user has a submission graded
class Unlock < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :exercise, :foreign_key => :exercise_name, :primary_key => :name,
    :conditions => proc { "exercises.course_id = #{self.course_id}" }
  # the DB validates uniqueness for (user_id, course_id, :exercise_name)

  def self.refresh_all_unlocks(course)
    Unlock.transaction do
      unlocks = {}
      course.unlocks.each do |u|
        unlocks[u.user_id] ||= {}
        unlocks[u.user_id][u.exercise_name] = u
      end

      for user in User.all
        refresh_unlocks_impl(course, user, unlocks[user.id])
      end
    end
  end

  def self.refresh_unlocks(course, user)
    Unlock.transaction do
      unlocks = course.unlocks.where(:user_id => user.id)
      by_exercise_name = Hash[unlocks.map {|u| [u.exercise_name, u]}]
      refresh_unlocks_impl(course, user, by_exercise_name)
    end
  end

private

  def self.refresh_unlocks_impl(course, user, user_unlocks_by_exercise_name)
    for exercise in course.exercises
      exists = !!user_unlocks_by_exercise_name[exercise.name]
      should_exist = exercise.unlock_spec_obj.permits_unlock_for?(user)
      if !exists && should_exist
        Unlock.create!(
          :user => user,
          :course => course,
          :exercise => exercise,
          :valid_after => exercise.unlock_spec_obj.valid_after
        )
      elsif exists && !should_exist
        user_unlocks_by_exercise_name[exercise.name].destroy
      end
    end
  end
end
