# frozen_string_literal: true

# Handles emailing notification to every participant
class CourseNotificationsController < ApplicationController
  before_action :set_organization

  def new
    course = Course.find(course_notification_params[:course_id])
    authorize! :send_mail_to_participants, course
    @notifier ||= CourseNotification.new
    @course = Course.find_by(id: params[:course_id])
    add_course_breadcrumb
    add_breadcrumb 'Course notification'
  end

  def create
    course = Course.find(course_notification_params[:course_id])
    authorize! :send_mail_to_participants, course

    participants = User.course_students(course)
    emails = participants.map(&:email).reject(&:blank?)

    notifier = course.course_notifications.create(course_notification_params[:course_notification].merge(sender_id: current_user.id))

    if notifier.message.blank?
      flash[:error] = 'Cannot send a blank message.'
      return redirect_to new_organization_course_course_notifications_path(@organization, course)
    end

    failed_emails = []
    emails.each do |email|
      raise 'Invalid e-mail' unless email =~ /\S+@\S+/
      CourseNotificationMailer.notification_email(
        reply_to: current_user.email,
        to: email,
        topic: notifier.topic,
        message: notifier.message
      ).deliver_now
    rescue StandardError
      logger.info "Error sending course notification to email #{email}: #{$!}"
      failed_emails << email
    end
    msg = +'Mail has been set succesfully'
    msg << " except for the following addresses: #{failed_emails.join(', ')}" unless failed_emails.empty?
    redirect_to organization_course_path(@organization, course), notice: msg
  end

  private

    def course_notification_params
      params.permit(:commit, :course_id, course_notification: %i[topic message])
    end

    def set_organization
      @organization = Organization.find_by(slug: params[:organization_id])
    end
end
