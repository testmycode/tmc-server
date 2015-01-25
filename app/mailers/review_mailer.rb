class ReviewMailer < ActionMailer::Base
  def review_email(review)
    settings = SiteSetting.value('emails')

    subject = '[TMC] Code Review'
    @review = review
    @url = settings['baseurl'].sub(/\/+$/, '') + "/submissions/#{review.submission.id}/reviews"
    from = settings['from']
    reply_to = review.reviewer.email
    mail(from: from, reply_to: reply_to, to: review.submission.user.email, subject: subject)
  end
end
