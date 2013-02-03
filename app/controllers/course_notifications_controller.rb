# Handles emailing notification to every participant
class CourseNotificationsController < ApplicationController
  before_filter :auth

  def new
    @notifier = CourseNotifications.new
  end

  def create
    course = Course.find_by_id(params[:course_id])

    participants = User.course_students(course)
    emails = participants.map { |participant| participant.email if participant.email }


    notifier = course.course_notifications.create(params[:course_notifications])
    notifier.user = current_user
    CourseNotificationMailer.update(
      from: current_user.email,
      to: emails.join(','),
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