# Handles emailing notification to every participant
class CourseNotificationsController < ApplicationController
  before_filter :auth

  def new
    @notifier ||= CourseNotification.new
  end

  def create
    course = Course.find(params[:course_id])

    participants = User.course_students(course)
    emails = participants.map(&:email).reject(&:nil?)

    notifier = course.course_notifications.create(params[:course_notification])
    notifier.user = current_user
    CourseNotificationMailer.notification_email(
      from: current_user.email,
      bcc: emails.join(','),
      topic: notifier.topic,
      message: notifier.message
    ).deliver
    redirect_to course_path(course), :notice => "Mail has been sent"
  end

private
  def auth
    authorize! :email, CourseNotification
  end


end