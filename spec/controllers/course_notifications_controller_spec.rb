# frozen_string_literal: true

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
      course_id: @course.id
    }
  end

  it 'should not allow a non-admin/non-teacher user to send email' do
    bypass_rescue

    @user = FactoryGirl.create(:user)
    controller.current_user = @user

    expect { post :create, params }.to raise_error(CanCan::AccessDenied)
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
      FactoryGirl.create(:submission, user: user, course: @course)
      user2 = FactoryGirl.create(:user, email: 'std@myschool.fi')
      FactoryGirl.create(:submission, user: user2, course: @course)
      FactoryGirl.create(:awarded_point, user_id: user.id, course_id: @course.id)
      FactoryGirl.create(:awarded_point, user_id: user2.id, course_id: @course.id)

      expect { post :create, params }.to change(ActionMailer::Base.deliveries, :size).by(2)

      recipients = ActionMailer::Base.deliveries.flat_map(&:to)
      expect(recipients).to include user.email
      expect(recipients).to include user2.email
      expect(ActionMailer::Base.deliveries.last.body.encoded).to include message
    end

    it "doesn't crash if some email addresses are invalid" do
      user = FactoryGirl.create(:user, email: 'student@some.edu.fi')
      FactoryGirl.create(:submission, user: user, course: @course)
      user2 = FactoryGirl.build(:user, email: 'student    @   edufi').tap { |u| u.save(validate: false) } # The invalid address
      FactoryGirl.create(:submission, user: user2, course: @course)
      FactoryGirl.create(:awarded_point, user_id: user.id, course_id: @course.id)
      FactoryGirl.create(:awarded_point, user_id: user2.id, course_id: @course.id)

      expect { post :create, params }.to change(ActionMailer::Base.deliveries, :size)

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
      Teachership.create(user: @teacher, organization: @organization)
      controller.current_user = @teacher

      post :create, params
      expect(response).to redirect_to(organization_course_path(@organization, @course))
    end
  end
end
