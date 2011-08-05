class Ability
  include CanCan::Ability

  def initialize(user)
    # CanCan ability reference: https://github.com/ryanb/cancan/wiki/Defining-Abilities
    
    if user.administrator?
      can :manage, :all
      can :refresh, Course
    else
      can :read, :all
      
      cannot :read, Submission
      can :read, Submission, :user_id => user.id
      can :create, Submission
    end
  end
end
