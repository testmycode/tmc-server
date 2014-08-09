# Keeps track of whether a (course, user)'s unlocks have yet to be computed, enabling lazy computation.
# A course refresh populates this table and the UnlockComputerTask background task
# consumes it by calling Unlock.refresh_unlocks on the entries. All code that accesses
# unlocks must ensure that UncomputedUnlock.resolve is called for the (course, user) first.
class UncomputedUnlock < ActiveRecord::Base
  belongs_to :course
  belongs_to :user

  def self.create_all_for_course(course)
    user_ids = User.course_students(course).pluck(:id)
    transaction do
      user_ids.each do |uid|
        # The obvious race condition here may result in a duplicate being inserted.
        # This is fine since Unlock.refresh_unlocks does a corresponding delete_all.
        unless UncomputedUnlock.where(:course_id => course.id, :user_id => uid).exists?
          UncomputedUnlock.create!(:course_id => course.id, :user_id => uid)
        end
      end
    end
  end

  def self.resolve(course, user)
    if find_by_course_id_and_user_id(course, user)
      Unlock.refresh_unlocks(course, user)
    end
  end
end
