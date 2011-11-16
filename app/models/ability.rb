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

      cannot :read, Submission
      can :read, Submission, :user_id => user.id
      can :create, Submission do |sub|
        sub.exercise.submittable_by?(user)
      end
    end
  end
end
