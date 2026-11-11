# typed: strict
# frozen_string_literal: true

class CourseTemplateRefreshChannel < ApplicationCable::Channel
  extend T::Sig

  sig { void }
  def subscribed
    course_template = CourseTemplate.find_by(id: params[:courseTemplateId])
    return reject unless course_template && can_follow_refresh?(course_template)
    stream_from "CourseTemplateRefreshChannel-#{course_template.id}"
  end

  sig { void }
  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private
    # Matches who is shown refresh progress: template admins and teachers of a course using the template.
    sig { params(course_template: CourseTemplate).returns(T::Boolean) }
    def can_follow_refresh?(course_template)
      # current_user is delegated from the connection at runtime, so Sorbet cannot see it.
      ability = Ability.new(T.unsafe(self).current_user)
      ability.can?(:create, CourseTemplate) || course_template.courses.any? { |course| ability.can?(:teach, course) }
    end
end
