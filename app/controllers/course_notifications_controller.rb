# Handles emailing notification to every participant
class CourseNotificationsController < ApplicationController
  before_filter :auth

  def new
    @notifier ||= CourseNotification.new
  end

  def create
    course = Course.find(course_notification_params[:course_id])

    participants = User.course_students(course)
    emails = participants.map(&:email).reject(&:blank?)

    notifier = course.course_notifications.create(course_notification_params[:course_notification].merge(sender_id: current_user.id))

    if notifier.message.blank?
      flash[:error] = 'Cannot send a blank message.'
      return redirect_to new_course_course_notifications_path(course)
    end

    failed_emails = []
    emails.each do |email|
      begin
        raise "Invalid e-mail" unless email =~ /\S+@\S+/
        CourseNotificationMailer.notification_email(
          from: current_user.email,
          to: email,
          topic: notifier.topic,
          message: notifier.message
        ).deliver
      rescue
        logger.info "Error sending course notification to email #{email}: #{$!}"
        failed_emails << email
      end
    end
    msg = "Mail has been set succesfully"
    msg << " except for the following addresses: #{failed_emails.join(", ")}" unless failed_emails.empty?
    redirect_to course_path(course), :notice => msg
  end

private
  def course_notification_params
    params.permit(:commit, :course_id, { course_notification: [:topic, :message] })
  end

  def auth
    authorize! :email, CourseNotification
  end
end
