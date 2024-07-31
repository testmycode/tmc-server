# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe FeedbackRepliesController, '#create', type: :controller do
  let(:student_email) { 'user@mydomain.com' }
  let(:reply_body) { 'A reply to an feedback answer...' }
  let(:answer) { FactoryBot.create(:feedback_answer) }
  let(:params) do
    {
      email: student_email,
      body: reply_body,
      answer_id: answer.id
    }
  end

  it 'should not allow a non-admin user to send a reply' do
    bypass_rescue

    @user = FactoryBot.create(:user)
    controller.current_user = @user

    ability = Ability.new(controller.current_user)

    expect(ability).not_to be_able_to(:reply, answer)
    expect { post :create, params: params }.to raise_error(CanCan::AccessDenied)
  end

  describe 'for an admin user' do
    let(:admin) { FactoryBot.create(:admin, email: 'admin@mydomain.com') }
    let(:url) { 'http://test.host/referer' }
    before do
      controller.current_user = admin
      request.env['HTTP_REFERER'] = url
    end

    it 'redirects to the url where the request came' do
      post :create, params: params
      expect(response).to redirect_to(url)
    end

    it 'associates a reply to feedback_answer' do
      expect { post :create, params: params }.to change { answer.replied? }.from(false).to(true)
      reply = answer.reply_to_feedback_answers.first
      expect(reply.from).to eq(admin.email)
      expect(reply.body).to eq(reply_body)
    end

    it 'sends a reply email to the user who gave the feedback' do
      expect { post :create, params: params }.to change(ActionMailer::Base.deliveries, :size).by(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.reply_to).to include(admin.email)
      expect(mail.to).to include(student_email)
      expect(mail.body.encoded).to include reply_body
    end
  end
end
