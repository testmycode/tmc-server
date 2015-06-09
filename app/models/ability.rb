# CanCan ability definitions.
#
# See: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
class Ability
  include CanCan::Ability

  def initialize(user)
    if user.administrator?
      can :manage, :all
      can :create, Course
      can :refresh, Course
      can :view, :participants_list
      can :rerun, Submission
      can :refresh_gdocs_spreadsheet, Course do |c|
        !c.spreadsheet_key.blank?
      end
      can :access_pghero
      can :read_vm_log, Submission
    else
      can :read, :all

      cannot :access_pghero
      cannot :read, User
      cannot :read, :code_reviews
      cannot :read, :course_information
      can :read, User, id: user.id
      can :create, User if SiteSetting.value(:enable_signup)

      cannot :read, Course
      can :read, Course do |c|
        c.visible_to?(user)
      end

      cannot :read, Exercise
      can :read, Exercise do |ex|
        ex.visible_to?(user)
      end
      can :download, Exercise do |ex|
        ex.downloadable_by?(user)
      end

      cannot :read, Submission
      can :read, Submission do |sub|
        sub.readable_by?(user)
      end

      can :create, Submission do |sub|
        sub.exercise.submittable_by?(user)
      end

      cannot :read, FeedbackAnswer
      can :create, FeedbackAnswer do |ans|
        ans.submission.user_id == user.id
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

      can :view_code_reviews, Course do |c|
        c.submissions.exists?(user_id: user.id, reviewed: true)
      end

      cannot :read, Certificate
      can :read, Certificate do |c|
        c.user == user
      end
      can :create, Certificate do |c|
        c.course.certificate_downloadable_for? user
      end

      cannot :reply, FeedbackAnswer

      can :create, :organization
      cannot :create, :organization if user.guest?

      can :request, :organization
      cannot :request, :organization if user.guest?

      cannot :manage_teachers, Organization
      can :manage_teachers, Organization do |o|
        o.teacher?(user)
      end

      cannot :teach, Organization
      can :teach, Organization do |o|
        o.teacher?(user) && !o.rejected? && !o.acceptance_pending?
      end

      cannot :teach, Course
      can :teach, Course do |c|
        return false if c.organization.rejected?
        c.organization.teacher?(user) || c.assistant?(user)
      end
    end
  end
end
