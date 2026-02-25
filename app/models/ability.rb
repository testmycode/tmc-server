# frozen_string_literal: true

# CanCan ability definitions.
#
# See: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
class Ability
  include CanCan::Ability

  def initialize(user)
    if user.administrator?
      can :manage, :all
      can :create, Course
      can :create, :custom_course
      cannot :refresh, Course
      can :refresh, Course, &:custom?
      can :view, :participants_list

      can :view, :unverified_organizations
      can :verify, :unverified_organizations
      can :disable, Organization

      can :rerun, Submission
      can :access, :pghero
      can :read_vm_log, Submission
      can :read, :instance_state
    else
      cannot :read, :instance_state
      can :read, :all

      cannot :access, :pghero
      cannot :read, User
      cannot :read, :code_reviews
      cannot :read, :course_information

      # This check is bit heavy with sql queries if used in views to iterate on lists
      can :read, User do |u|
        u.readable_by?(user)
      end

      can :create, User if SiteSetting.value(:enable_signup)
      cannot :destroy, User
      can :destroy, User do |u|
        u == user
      end
      cannot :update, User
      can :update, User do |u|
        u == user
      end

      cannot :read, Course
      can :read, Course do |c|
        user.administrator? ||
          user.teacher?(c.organization) ||
          user.assistant?(c) ||
          (
            c.initial_refresh_ready? &&
              (!c.disabled? && !c.hidden? &&
            (
              c.hidden_if_registered_after.nil? ||
              c.hidden_if_registered_after > Time.now ||
              (!user.guest? && c.hidden_if_registered_after > user.created_at)
            ) || user.student_in_course?(c))
          )
      end

      can :create, Course do |c|
        can? :teach, c.organization
      end

      can :edit, Course do |c|
        can? :teach, c.organization
      end

      can :refresh, Course do |c|
        (c.taught_by?(user) || c.assistant?(user)) &&
          c.custom? # user can only refresh his/her custom course.
      end

      cannot :read, Exercise
      can :read, Exercise do |ex|
        ex.visible_to?(user) || can?(:teach, ex.course)
      end
      can :download, Exercise do |ex|
        ex.downloadable_by?(user)
      end

      can :see_points, Exercise do |ex|
        (!ex.hide_submission_results? && !ex.course.hide_submission_results?) || can?(:teach, ex.course)
      end

      cannot :read, Submission
      can :read, Submission do |sub|
        sub.readable_by?(user) || can?(:teach, sub.course)
      end

      can :create, Submission do |sub|
        sub.exercise.submittable_by?(user)
      end

      can :update, Submission do |sub|
        can? :teach, sub.course
      end

      can :rerun, Submission do |sub|
        can? :teach, sub.course.organization
      end

      can :download, Submission do |sub|
        !sub.course.hide_submission_results? && !sub.exercise.hide_submission_results? && (can?(:read, sub) || sub.paste_visible_for?(user))
      end

      can :read_results, Submission do |sub|
        (!sub.course.hide_submission_results? && !sub.exercise.hide_submission_results?) || (can? :teach, sub.course)
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
        # course = sol.exercise.course
        sol.visible_to?(user)
      end

      cannot :manage, Review
      can :manage, Review do |r|
        r.manageable_by?(user) || can?(:teach, r.submission.course)
      end
      can :read, Review do |r|
        r.readable_by?(user) || can?(:teach, r.submission.course)
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
        c.submissions.exists?(user_id: user.id, reviewed: true) || can?(:teach, c)
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

      can :view_statistics, Organization do |o|
        can? :teach, o
      end

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

      can :clone, CourseTemplate, &:clonable?

      can :request, :organization
      cannot :request, :organization if user.guest?

      cannot :manage_teachers, Organization
      can :manage_teachers, Organization do |o|
        o.teacher?(user)
      end

      can :remove_teacher, Organization do |o|
        can? :teach, o
      end

      can :modify_assistants, Course do |c|
        can? :teach, c
      end

      can :edit, Organization do |o|
        can? :teach, o
      end

      can :toggle_visibility, Organization do |o|
        can? :teach, o
      end

      can :toggle_submission_result_visibility, Course do |c|
        can? :teach, c
      end

      can :see_points, Course do |c|
        !c.hide_submission_results? || (can? :teach, c)
      end

      cannot :teach, Organization
      can :teach, Organization do |o|
        o.teacher?(user) && !o.disabled?
      end

      cannot :teach, Course
      can :teach, Course do |c|
        can?(:teach, c.organization) || c.assistant?(user)
        # c.organization.teacher?(user) || c.assistant?(user)
      end

      cannot :email, CourseNotification

      can :view_external_scoreboard_url, Course do |c|
        can?(:teach, c) || User.course_students(c).include?(user)
      end

      can :view_participant_information, User do |u|
        !user.guest? && u.readable_by?(user)
      end

      can :view_participant_list, Organization do |o|
        can?(:teach, o)
      end
    end
  end
end
