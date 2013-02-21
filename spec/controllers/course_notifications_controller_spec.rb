require 'spec_helper'

describe CourseNotificationsController do

  let(:topic) { "Hi all" }
  let(:message) { "A long message to every participant on some course..." }
  let(:course) { Factory.create(:course) }
  let(:params) {
    {
      course_notification:{
        topic: topic,
        message: message
      },
      course_id: course.id
    }
  }

  it "should not allow a non-admin user to send email" do
    @user = Factory.create(:user)
    controller.current_user = @user
    expect { post :create, params }.to raise_error
  end

  describe "for an admin user " do
    let(:admin){ Factory.create(:admin, :email => "admin@mydomain.com") }
    before do
      controller.current_user = admin
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
      aw1 = Factory.create(:awarded_point, user_id: user.id, course_id: course.id)
      aw2 = Factory.create(:awarded_point, user_id: user2.id, course_id: course.id)
      expect { post :create, params }.to change(ActionMailer::Base.deliveries,:size).by(2)

      mail_first = ActionMailer::Base.deliveries[-2]
      mail_first.to.should include user.email
      mail_first.body.encoded.should include message
      mail_first.to.should_not include user2.email

      mail_last = ActionMailer::Base.deliveries[-1]
      mail_last.to.should include user2.email
      mail_last.body.encoded.should include message
      mail_last.to.should_not include user.email
    end
  end

end
