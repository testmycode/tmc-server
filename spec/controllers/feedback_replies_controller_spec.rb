require 'spec_helper'

describe FeedbackRepliesController, "#create" do
  let(:student_email) { "user@mydomain.com" }
  let(:reply_body) { "A reply to an feedback answer..." }
  let(:answer) { Factory.create(:feedback_answer) }
  let(:params) {
    {
      :email => student_email,
      :body => reply_body,
      :answer_id => answer.id
    }
  }

  it "should not allow a non-admin user to send a reply" do
    @user = Factory.create(:user)
    controller.current_user = @user

    expect { post :create, params }.to raise_error
  end

  describe "for an admin user " do
    let(:admin){ Factory.create(:admin, :email => "admin@mydomain.com") }
    let(:url){ 'http://url.where.we.arrived.com' }
    before do
      controller.current_user = admin
      request.env["HTTP_REFERER"] = url
    end

    it "redirects to the url where the request came" do
      post :create, params
      response.should redirect_to(url)
    end

    it "associates a reply to feedback_answer" do
      expect { post :create, params }.to change{answer.replied?}.from(false).to(true)
      reply = answer.reply_to_feedback_answers.first
      reply.from.should == admin.email
      reply.body.should == reply_body
    end

    it "sends a reply email to the user who gave the feedback" do
      expect { post :create, params }.to change(ActionMailer::Base.deliveries,:size).by(1)
      mail = ActionMailer::Base.deliveries.last
      mail.from.should include(admin.email)
      mail.to.should include(student_email)
      mail.body.encoded.should include reply_body
    end
  end

end