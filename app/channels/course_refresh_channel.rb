class CourseRefreshChannel < ApplicationCable::Channel
  def subscribed
    stream_from "CourseRefresh_user_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def received(data)
    Rails.logger.log("Hephep")
    return unless data['ping']
  end
end
