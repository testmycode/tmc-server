class Ability
  include CanCan::Ability

  def initialize(user, session)
    # CanCan ability reference: https://github.com/ryanb/cancan/wiki/Defining-Abilities
    # About the nonstandard second session parameter: https://github.com/ryanb/cancan/issues/133

    if user.administrator?
      can :manage, :all
      can :refresh, Course
    else
      can :read, :all
      
      cannot :read, User
      can :read, User, :id => user.id
      can :create, User if SiteSetting.value(:enable_signup)

      cannot :read, Course
      can :read, Course do |c|
        c.visible_to?(user)
      end

      cannot :read, Exercise
      can :read, Exercise do |ex|
        ex.visible_to?(user)
      end

      cannot :read, Submission
      can :read, Submission, :user_id => user.id
      can :create, Submission do |sub|
        sub.exercise.submittable_by?(user)
      end

      cannot :read, FeedbackAnswer
      can :create, FeedbackAnswer do |ans|
        ans.submission.user_id == user.id
      end

      can :create, StudentEvent do |ev|
        ev.user_id = user.id
      end
      
      cannot :read, Solution
      can :read, Solution do |sol|
        sol.visible_to?(user)
      end

      cannot :mark_as_read, Review
      can :mark_as_read, Review do |r|
        r.submission.user_id == user.id
      end
      cannot :mark_as_unread, Review
      can :mark_as_unread, Review do |r|
        r.submission.user_id == user.id
      end
    end
  end
end
