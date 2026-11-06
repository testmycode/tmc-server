# typed: strict
# frozen_string_literal: true

class CourseTemplateRefreshChannel < ApplicationCable::Channel
  extend T::Sig

  sig { void }
  def subscribed
    stream_from "CourseTemplateRefreshChannel-#{params[:courseTemplateId]}"
  end

  sig { void }
  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
