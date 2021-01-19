# frozen_string_literal: true

class CourseRefreshChannel < ApplicationCable::Channel
  def subscribed
    stream_from "CourseRefreshChannel-course-id-#{params[:courseId]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
