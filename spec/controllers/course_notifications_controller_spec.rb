require 'spec_helper'
require 'cancan/matchers'

describe CourseNotificationsController, :type => :controller do

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
    bypass_rescue

    @user = Factory.create(:user)
    controller.current_user = @user

    ability = Ability.new(controller.current_user)

    expect(ability).not_to be_able_to(:email, CourseNotification)
    expect { post :create, params }.to raise_error
  end

  describe "for an admin user " do
    let(:admin){ Factory.create(:admin, :email => "admin@mydomain.com") }
    before do
      controller.current_user = admin
    end

    it "redirects to the course page" do
      post :create, params
      expect(response).to redirect_to(course_path(course))
    end

    it "sends a email for every participant on course" do
      # submissions and points are added so that the user is considered to be on the course
      user = Factory.create(:user, email: 'student@some.edu.fi')
      sub1 = Factory.create(:submission, user: user, course: course)
      user2 = Factory.create(:user, email: 'std@myschool.fi')
      sub2 = Factory.create(:submission, user: user2, course: course)
      aw1 = Factory.create(:awarded_point, user_id: user.id, course_id: course.id)
      aw2 = Factory.create(:awarded_point, user_id: user2.id, course_id: course.id)

      expect { post :create, params }.to change(ActionMailer::Base.deliveries, :size).by(2)

      mail_first = ActionMailer::Base.deliveries[-2]
      expect(mail_first.to).to include user.email
      expect(mail_first.body.encoded).to include message

      mail_last = ActionMailer::Base.deliveries.last
      expect(mail_last.to).to include user2.email
      expect(mail_last.body.encoded).to include message
    end

    it "doesn't crash if some email addresses are invalid" do
      user = Factory.create(:user, email: 'student@some.edu.fi')
      sub1 = Factory.create(:submission, user: user, course: course)
      user2 = Factory.create(:user, email: 'std  @ myschool . fi') #The invalid address
      sub2 = Factory.create(:submission, user: user2, course: course)
      aw1 = Factory.create(:awarded_point, user_id: user.id, course_id: course.id)
      aw2 = Factory.create(:awarded_point, user_id: user2.id, course_id: course.id)

      expect { post :create, params }.to change(ActionMailer::Base.deliveries, :size).by(1)

      mail_first = ActionMailer::Base.deliveries.last
      expect(mail_first.to).to include user.email
      expect(mail_first.body.encoded).to include message
    end

    it "refuses to send a blank message" do
      params[:course_notification][:message] = ''
      post :create, params
      expect(response).to redirect_to(new_course_course_notifications_path(course))
      expect(flash[:error]).not_to be_empty
    end

  end

end
