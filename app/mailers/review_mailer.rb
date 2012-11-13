class ReviewMailer < ActionMailer::Base
  def review_email(review)
    settings = SiteSetting.value('emails')

    subject = '[TMC] Code Review'
    @review = review
    @url = settings['baseurl'].sub(/\/+$/, '') + "/submissions/#{review.submission.id}/reviews"
    from = if settings['reviews_from_reviewer'] then review.reviewer.email else settings['from'] end
    mail(:from => from, :to => review.submission.user.email, :subject => subject)
  end
end
