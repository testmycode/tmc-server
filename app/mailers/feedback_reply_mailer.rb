# typed: strict
# frozen_string_literal: true

class FeedbackReplyMailer < ActionMailer::Base
  extend T::Sig
  sig { params(reply_to: String, to: T.nilable(String), body: T.nilable(String), exercise_name: String).void }
  def feedback_email(reply_to, to, body, exercise_name)
    from = SiteSetting.value('emails')['from']
    subject = "[TMC] Reply to your feedback for exercise #{exercise_name}"
    @mailbody = T.let(body, T.nilable(String))
    mail(from: from, reply_to: reply_to, to: to, subject: subject)
  end
end
