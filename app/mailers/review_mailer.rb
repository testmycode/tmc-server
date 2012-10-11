class ReviewMailer < ActionMailer::Base
  def review_email(review)
    settings = SiteSetting.value('emails')

    subject = '[TMC] Code Review'
    @review = review
    @url = settings['baseurl'].sub(/\/+$/, '') + "/submissions/#{review.submission.id}/reviews"
    mail(:from => settings['from'], :to => review.submission.user.email, :subject => subject)
  end
end
