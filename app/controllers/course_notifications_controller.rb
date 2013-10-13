# Handles emailing notification to every participant
class CourseNotificationsController < ApplicationController
  before_filter :auth

  def new
    @notifier ||= CourseNotification.new
  end

  def create
    course = Course.find(params[:course_id])

    participants = User.course_students(course)
    emails = participants.map(&:email).reject(&:blank?)

    notifier = course.course_notifications.create(params[:course_notification], sender_id: current_user.id)

    invalid_emails = []
    emails.each do |email|
      begin
        CourseNotificationMailer.notification_email(
          from: current_user.email,
          to: email,
          topic: notifier.topic,
          message: notifier.message
        ).deliver
      rescue
        invalid_emails << email
      end
    end
    msg = "Mail has been set succesfully"
    msg << " to valid addresses, invalid addresses: #{invalid_emails.join(", ")}" unless invalid_emails.empty?
    redirect_to course_path(course), :notice => msg
  end

private
  def auth
    authorize! :email, CourseNotification
  end


end
