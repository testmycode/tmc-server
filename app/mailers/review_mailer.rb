# typed: strict
# frozen_string_literal: true

class ReviewMailer < ActionMailer::Base
  extend T::Sig
  sig { params(review: Review).void }
  def review_email(review)
    settings = SiteSetting.value('emails')
    # belongs_to associations are required, so a saved review has both.
    submission = T.must(review.submission)

    subject = '[TMC] Code Review'
    @review = T.let(review, T.nilable(Review))
    @url = T.let(settings['baseurl'].sub(/\/+$/, '') + "/submissions/#{submission.id}/reviews", T.nilable(String))
    from = settings['from']
    reply_to = review.reviewer&.email
    mail(from: from, reply_to: reply_to, to: T.must(submission.user).email, subject: subject)
  end
end
