# typed: strict

# frozen_string_literal: true

class CourseNotificationMailer < ActionMailer::Base
  extend T::Sig
  include ActionView::Helpers::SanitizeHelper

  # `params` keys: :reply_to, :to, :topic, :message.
  sig { params(params: T::Hash[Symbol, T.nilable(String)]).void }
  def notification_email(params = {})
    from = SiteSetting.value('emails')['from']
    reply_to = params[:reply_to]
    subject = params[:topic]
    message = T.must(params[:message])
    @html_mailbody = T.let(message.gsub("\n", '<br>'), T.nilable(String))
    @text_mailbody = T.let(strip_tags(message), T.nilable(String))

    to = params[:to]
    mail(from: from, reply_to: reply_to, to: to, subject: subject)
  end
end
