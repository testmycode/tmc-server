require 'spec_helper'
require 'cancan/matchers'

describe CourseNotificationsController, type: :controller do
  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @course = FactoryGirl.create(:course, organization: @organization)
  end

  let(:topic) { 'Hi all' }
  let(:message) { 'A long message to every participant on some course...' }
  let(:params) do
    {
      course_notification: {
        topic: topic,
        message: message
      },
      organization_id: @organization.slug,
      course_name: @course.name
    }
  end

  it 'should not allow a non-admin/non-teacher user to send email' do
    bypass_rescue

    @user = FactoryGirl.create(:user)
    controller.current_user = @user

    expect { post :create, params }.to raise_error
  end

  describe 'for an admin user' do
    let(:admin) { FactoryGirl.create(:admin, email: 'admin@mydomain.com') }
    before do
      controller.current_user = admin
    end

    it 'redirects to the course page' do
      post :create, params
      expect(response).to redirect_to(organization_course_path(@organization, @course))
    end

    it 'sends a email for every participant on course' do
      # submissions and points are added so that the user is considered to be on the course
      user = FactoryGirl.create(:user, email: 'student@some.edu.fi')
      sub1 = FactoryGirl.create(:submission, user: user, course: @course)
      user2 = FactoryGirl.create(:user, email: 'std@myschool.fi')
      sub2 = FactoryGirl.create(:submission, user: user2, course: @course)
      aw1 = FactoryGirl.create(:awarded_point, user_id: user.id, course_id: @course.id)
      aw2 = FactoryGirl.create(:awarded_point, user_id: user2.id, course_id: @course.id)

      expect { post :create, params }.to change(ActionMailer::Base.deliveries, :size).by(2)

      mail_first = ActionMailer::Base.deliveries[-2]
      expect(mail_first.to).to include user.email
      expect(mail_first.body.encoded).to include message

      mail_last = ActionMailer::Base.deliveries.last
      expect(mail_last.to).to include user2.email
      expect(mail_last.body.encoded).to include message
    end

    it "doesn't crash if some email addresses are invalid" do
      user = FactoryGirl.create(:user, email: 'student@some.edu.fi')
      sub1 = FactoryGirl.create(:submission, user: user, course: @course)
      user2 = FactoryGirl.create(:user, email: 'std  @ myschool . fi') # The invalid address
      sub2 = FactoryGirl.create(:submission, user: user2, course: @course)
      aw1 = FactoryGirl.create(:awarded_point, user_id: user.id, course_id: @course.id)
      aw2 = FactoryGirl.create(:awarded_point, user_id: user2.id, course_id: @course.id)

      expect { post :create, params }.to change(ActionMailer::Base.deliveries, :size).by(1)

      mail_first = ActionMailer::Base.deliveries.last
      expect(mail_first.to).to include user.email
      expect(mail_first.body.encoded).to include message
    end

    it 'refuses to send a blank message' do
      params[:course_notification][:message] = ''
      post :create, params
      expect(response).to redirect_to(new_organization_course_course_notifications_path(@organization, @course))
      expect(flash[:error]).not_to be_empty
    end
  end

  describe 'for a teacher' do
    it 'allows to send email' do
      @teacher = FactoryGirl.create(:user, email: 'admin@mydomain.com')
      Teachership.create(user: @teacher,organization: @organization)
      controller.current_user = @teacher

      post :create, params
      expect(response).to redirect_to(organization_course_path(@organization, @course))
    end
  end
end
