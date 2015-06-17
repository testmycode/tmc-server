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
      can :read, User do |u|
        u.readable_by?(user)
      end
      can :create, User if SiteSetting.value(:enable_signup)

      cannot :read, Course
      can :read, Course do |c|
        c.visible_to?(user)
      end
      can :create, Course do |c|
        c.taught_by?(user)
      end
      can :refresh, Course do |c|
        c.taught_by?(user)
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

      can :update, Submission do |sub|
        user.teacher?(sub.course.organization)
      end

      cannot :manage_feedback_questions, Course
      can :manage_feedback_questions, Course do |c|
        user.teacher?(c.organization)
      end

      cannot :read, FeedbackAnswer
      can :read_feedback_answers, Course do |c|
        user.teacher?(c.organization)
      end
      can :read_feedback_answers, Exercise do |e|
        user.teacher?(e.course.organization)
      end

      cannot :read, FeedbackQuestion
      can :read_feedback_questions, Course do |c|
        user.teacher?(c.organization)
      end
      can :read_feedback_questions, Exercise do |e|
        user.teacher?(e.course.organization)
      end

      can :reply_feedback_answer, FeedbackAnswer do |ans|
        user.teacher?(ans.course.organization)
      end

      can :create, FeedbackAnswer do |ans|
        ans.submission.user_id == user.id
      end

      cannot :read, Solution
      can :read, Solution do |sol|
        sol.visible_to?(user)
      end

      cannot :manage, Review
      can :manage, Review do |r|
        r.manageable_by?(user)
      end
      can :read, Review do |r|
        r.readable_by?(user)
      end

      can :create_review, Submission do |s|
        user.teacher?(s.course.organization)
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
        c.submissions.exists?(user_id: user.id, reviewed: true) || user.teacher?(c.organization)
      end

      can :list_code_reviews, Course do |c|
        user.teacher?(c.organization)
      end

      cannot :create, AwardedPoint
      can :create, AwardedPoint do |ap|
        ap.creatable_by?(user)
      end

      cannot :reply, FeedbackAnswer
      cannot :email, CourseNotification

      cannot :read, CourseTemplate
      can :prepare_course, CourseTemplate

      cannot :clone, CourseTemplate
      can :clone, CourseTemplate do |ct|
        ct.clonable?
      end

      can :request, :organization
      cannot :request, :organization if user.guest?

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
