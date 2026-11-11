# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe ReviewMailer, type: :mailer do
  before :each do
    settings = SiteSetting.all_settings['emails']
    settings['baseurl'] = 'http://example.com/foo'
    settings['from'] = 'noreply@example.com'
  end

  let(:review) { FactoryBot.create(:review) }

  it 'sets reply-to to the reviewer' do
    mail = ReviewMailer.review_email(review)

    expect(mail.reply_to).to eq([review.reviewer.email])
  end

  it 'sends without a reply-to when the reviewer has been deleted' do
    review.update_column(:reviewer_id, nil)

    mail = ReviewMailer.review_email(review.reload)

    expect(mail.to).to eq([review.submission.user.email])
    expect(mail.reply_to).to be_nil
  end
  it 'names the exercise even when it has been removed from the course' do
    exercise_name = review.submission.exercise_name
    review.submission.exercise.update_column(:name, 'removed-by-refresh')

    mail = ReviewMailer.review_email(Review.find(review.id))

    expect(mail.text_part.body.to_s).to include(exercise_name)
  end
end
