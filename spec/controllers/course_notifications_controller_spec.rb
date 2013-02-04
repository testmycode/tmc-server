require 'spec_helper'

describe CourseNotificationsController do

  let(:topic) { "Hi all" }
  let(:message) { "A long message to every participant on some course..." }
  let(:course) { Factory.create(:course) }
  let(:params) {
    {
      course_id: course.id,
      topic: topic,
      message: message
    }
  }

  it "should not allow a non-admin user to send email" do
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
      response.should redirect_to(course_path(course))
    end

    it "sends a email for every participant on course" do
      user = Factory.create(:user, email: 'student@some.edu.fi')
      user2 = Factory.create(:user, email: 'std@myschool.fi')
      sub1 = Factory.create(:submission, user: user, course: course)
      sub2 = Factory.create(:submission, user: user2, course: course)
      expect { post :create, params }.to change(ActionMailer::Base.deliveries,:size).by(1)
      mail = ActionMailer::Base.deliveries.last
      mail.bcc.should
    end
  end

end