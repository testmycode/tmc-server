# frozen_string_literal: true

class CourseTemplateRefreshChannel < ApplicationCable::Channel
  def subscribed
    stream_from "CourseTemplateRefreshChannel-course-id-#{params[:courseTemplateId]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
