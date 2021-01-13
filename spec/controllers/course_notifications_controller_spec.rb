# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe CourseNotificationsController, type: :controller do
  before :each do
    @organization = FactoryBot.create(:accepted_organization)
    @course = FactoryBot.create(:course, organization: @organization)
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

    @user = FactoryBot.create(:user)
    controller.current_user = @user

    expect { post :create, params: params }.to raise_error(CanCan::AccessDenied)
  end

  describe 'for an admin user' do
    let(:admin) { FactoryBot.create(:admin, email: 'admin@mydomain.com') }
    before do
      controller.current_user = admin
    end

    it 'redirects to the course page' do
      post :create, params: params
      expect(response).to redirect_to(organization_course_path(@organization, @course))
    end

    it 'sends a email for every participant on course' do
      # submissions and points are added so that the user is considered to be on the course
      user = FactoryBot.create(:user, email: 'student@some.edu.fi')
      FactoryBot.create(:submission, user: user, course: @course)
      user2 = FactoryBot.create(:user, email: 'std@myschool.fi')
      FactoryBot.create(:submission, user: user2, course: @course)
      FactoryBot.create(:awarded_point, user_id: user.id, course_id: @course.id)
      FactoryBot.create(:awarded_point, user_id: user2.id, course_id: @course.id)

      expect { post :create, params: params }.to change(ActionMailer::Base.deliveries, :size).by(2)

      recipients = ActionMailer::Base.deliveries.flat_map(&:to)
      expect(recipients).to include user.email
      expect(recipients).to include user2.email
      expect(ActionMailer::Base.deliveries.last.body.encoded).to include message
    end

    it "doesn't crash if some email addresses are invalid" do
      user = FactoryBot.create(:user, email: 'student@some.edu.fi')
      FactoryBot.create(:submission, user: user, course: @course)
      user2 = FactoryBot.build(:user, email: 'student    @   edufi').tap { |u| u.save(validate: false) } # The invalid address
      FactoryBot.create(:submission, user: user2, course: @course)
      FactoryBot.create(:awarded_point, user_id: user.id, course_id: @course.id)
      FactoryBot.create(:awarded_point, user_id: user2.id, course_id: @course.id)

      expect { post :create, params: params }.to change(ActionMailer::Base.deliveries, :size)

      mail_first = ActionMailer::Base.deliveries.last
      expect(mail_first.to).to include user.email
      expect(mail_first.body.encoded).to include message
    end

    it 'refuses to send a blank message' do
      params[:course_notification][:message] = ''
      post :create, params: params
      expect(response).to redirect_to(new_organization_course_course_notifications_path(@organization, @course))
      expect(flash[:error]).not_to be_empty
    end
  end

  describe 'for a teacher' do
    it 'allows to send email' do
      @teacher = FactoryBot.create(:user, email: 'admin@mydomain.com')
      Teachership.create(user: @teacher, organization: @organization)
      controller.current_user = @teacher

      post :create, params: params
      expect(response).to redirect_to(organization_course_path(@organization, @course))
    end
  end
end
