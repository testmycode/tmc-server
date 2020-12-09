# frozen_string_literal: true

require 'spec_helper'

describe Setup::CourseFinisherController, type: :controller do
  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @course = FactoryGirl.create(:course, organization: @organization)
    @teacher = FactoryGirl.create(:user)
    @user = FactoryGirl.create(:user)
    Teachership.create!(user: @teacher, organization: @organization)
  end

  describe 'As organization teacher' do
    before :each do
      controller.current_user = @teacher
    end

    describe 'GET index' do
      it 'redirects to setup root if not setup wizard active' do
        get :index, organization_id: @organization.slug, course_id: @course.id
        expect(session[:ongoing_course_setup]).to be_nil
        expect(response).to redirect_to(setup_start_index_path)
      end
    end

    describe 'POST create' do
      it 'makes course enabled' do
        post :create,
             organization_id: @organization.slug,
             course_id: @course.id,
             commit: 'Publish now'
        expect(assigns(:course).enabled?).to be(true)
        expect(response).to redirect_to(redirect_to(organization_course_path(@organization, @course)))
      end

      it 'makes course disabled' do
        post :create,
             organization_id: @organization.slug,
             course_id: @course.id,
             commit: 'Finish and publish later'
        expect(assigns(:course).disabled?).to be(true)
        expect(response).to redirect_to(redirect_to(organization_course_path(@organization, @course)))
      end

      it 'resets ongoing course setup session' do
        init_session
        expect(session[:ongoing_course_setup]).not_to be_nil
        post :create,
             organization_id: @organization.slug,
             course_id: @course.id,
             commit: 'Publish now'
        expect(session[:ongoing_course_setup]).to be_nil
      end
    end
  end

  describe 'As non-teacher' do
    before :each do
      controller.current_user = @user
    end

    it 'should not allow any access' do
      get :index, organization_id: @organization.slug, course_id: @course.id
      expect(response.code.to_i).to eq(403)
      post :create,
           organization_id: @organization.slug,
           course_id: @course.id,
           commit: 'Publish now'
      expect(response.code.to_i).to eq(403)
    end
  end

  def init_session
    session[:ongoing_course_setup] = {
      course_id: nil,
      phase: 1,
      started: Time.now
    }
  end
end
