# CanCan ability definitions.
#
# See: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
class Ability
  include CanCan::Ability

  def initialize(user)
    if user.administrator?
      can :manage, :all
      can :create, Course
      cannot :refresh, Course
      can :refresh, Course do |c|
        c.custom?
      end
      can :view, :participants_list
      can :view, :organization_requests
      can :accept, :organization_requests
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

      # This check is bit heavy with sql queries if used in views to iterate on lists
      can :read, User do |u|
        u.readable_by?(user)
      end

      can :create, User if SiteSetting.value(:enable_signup)

      cannot :read, Course
      can :read, Course do |c|
        c.visible_to?(user) || (can? :teach, c)
      end

      can :create, Course do |c|
        can? :teach, c.organization
      end

      can :refresh, Course do |c|
        c.taught_by?(user) &&
            c.custom? # user can only refresh his/her custom course.
      end

      cannot :read, Exercise
      can :read, Exercise do |ex|
        ex.visible_to?(user) || (can? :teach, ex.course)
      end
      can :download, Exercise do |ex|
        ex.downloadable_by?(user)
      end

      cannot :read, Submission
      can :read, Submission do |sub|
        sub.readable_by?(user) || (can? :teach, sub.course)
      end

      can :create, Submission do |sub|
        sub.exercise.submittable_by?(user)
      end

      can :update, Submission do |sub|
        can? :teach, sub.course
      end

      cannot :manage_feedback_questions, Course
      can :manage_feedback_questions, Course do |c|
        can? :teach, c
      end

      cannot :read, FeedbackAnswer
      can :read_feedback_answers, Course do |c|
        can? :teach, c
      end
      can :read_feedback_answers, Exercise do |e|
        can? :teach, e.course
      end

      cannot :read, FeedbackQuestion
      can :read_feedback_questions, Course do |c|
        can? :teach, c
      end
      can :read_feedback_questions, Exercise do |e|
        can? :teach, e.course
      end

      can :reply_feedback_answer, FeedbackAnswer do |ans|
        can? :teach, ans.course
      end

      can :create, FeedbackAnswer do |ans|
        ans.submission.user_id == user.id
      end

      cannot :read, Solution
      can :read, Solution do |sol|
        sol.visible_to?(user) || (can? :teach, sol.exercise.course)
      end

      cannot :manage, Review
      can :manage, Review do |r|
        r.manageable_by?(user) || (can? :teach, r.submission.course)
      end
      can :read, Review do |r|
        r.readable_by?(user) || (can? :teach, r.submission.course)
      end

      can :create_review, Course do |c|
        can? :teach, c
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
        c.submissions.exists?(user_id: user.id, reviewed: true) || (can? :teach, c)
      end

      can :list_code_reviews, Course do |c|
        can? :teach, c
      end

      cannot :create, AwardedPoint
      can :create, AwardedPoint do |ap|
        can? :teach, ap.course
      end

      cannot :read, Certificate
      can :read, Certificate do |c|
        c.user == user
      end
      can :create, Certificate do |c|
        c.course.certificate_downloadable_for? user
      end

      cannot :reply, FeedbackAnswer

      can :request, :organization
      cannot :request, :organization if user.guest?

      can :view_statistics, Organization

      can :list_user_emails, Course do |c|
        can? :teach, c
      end

      can :send_mail_to_participants, Course do |c|
        can? :teach, c
      end

      can :manage_deadlines, Course do |c|
        can? :teach, c
      end

      can :manage_unlocks, Course do |c|
        can? :teach, c
      end

      can :manage_exercises, Course do |c|
        can? :teach, c.organization
      end

      can :edit_course_paramaters, Course do |c|
        can? :teach, c.organization
      end

      cannot :read, CourseTemplate
      can :prepare_course, CourseTemplate

      #cannot :clone, CourseTemplate
      can :clone, CourseTemplate do |ct|
        ct.clonable?
      end

      can :request, :organization
      cannot :request, :organization if user.guest?

      cannot :manage_teachers, Organization
      can :manage_teachers, Organization do |o|
        o.teacher?(user)
      end

      can :remove_teacher, Organization do |o|
        can? :teach, o
      end

      can :remove_assistant, Course do |c|
        can? :teach, c.organization
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

      can :toggle_visibility, Organization do |o|
        can? :teach, o
      end

      cannot :email, CourseNotification
    end
  end
end
