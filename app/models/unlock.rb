
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

  def self.refresh_unlocks(course, user)
    Unlock.transaction do
      unlocks = course.unlocks.where(:user_id => user.id)
      unlocks_by_name = Hash[unlocks.map {|u| [u.exercise_name, u]}]
      for exercise in course.exercises
        exists = !!unlocks_by_name[exercise.name]
        should_exist = exercise.unlock_spec_obj.permits_unlock_for?(user)
        if !exists && should_exist
          Unlock.create!(
            :user => user,
            :course => course,
            :exercise => exercise,
            :valid_after => exercise.unlock_spec_obj.valid_after
          )
        elsif exists && !should_exist
          unlocks_by_name[exercise.name].destroy
        end
      end
    end
  end
end
