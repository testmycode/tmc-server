# frozen_string_literal: true

require 'spec_helper'

describe ExercisesController, type: :controller do
  describe 'GET show' do
    before :each do
      @organization = FactoryGirl.create(:accepted_organization)
      @course = FactoryGirl.create(:course)
      @course.organization = @organization
    end
    let!(:exercise) { FactoryGirl.create(:exercise, course: @course) }

    def get_show
      get :show, params: { organization_id: @organization.slug, id: exercise.id }
    end

    describe 'for guests' do
      it 'should not show submissions' do
        get_show
        expect(assigns[:submissions]).to be_nil
      end
    end

    describe 'for users' do
      let!(:user) { FactoryGirl.create(:user) }
      before :each do
        controller.current_user = user
      end
      it "should not show the user's submissions" do
        s1 = FactoryGirl.create(:submission, course: @course, exercise: exercise, user: user)
        s2 = FactoryGirl.create(:submission, course: @course, exercise: exercise)

        get_show

        expect(assigns[:submissions]).not_to be_nil
        expect(assigns[:submissions]).to include(s1)
        expect(assigns[:submissions]).not_to include(s2)
      end
    end

    describe 'for administrators' do
      before :each do
        controller.current_user = FactoryGirl.create(:admin)
      end
      it 'should show all submissions' do
        s1 = FactoryGirl.create(:submission, course: @course, exercise: exercise)
        s2 = FactoryGirl.create(:submission, course: @course, exercise: exercise)
        irrelevant = FactoryGirl.create(:submission)

        get_show

        expect(assigns[:submissions]).not_to be_nil
        expect(assigns[:submissions]).to include(s1)
        expect(assigns[:submissions]).to include(s2)
        expect(assigns[:submissions]).not_to include(irrelevant)
      end
    end
  end

  describe 'POST set_disabled_statuses' do
    before :each do
      @organization = FactoryGirl.create(:accepted_organization)
      @course = FactoryGirl.create(:course, organization: @organization)
      @ex1 = FactoryGirl.create(:exercise, course: @course)
      @ex2 = FactoryGirl.create(:exercise, course: @course)
      @ex3 = FactoryGirl.create(:exercise, course: @course)
      @teacher = FactoryGirl.create(:user)
      Teachership.create!(organization: @organization, user: @teacher)
      controller.current_user = @teacher
    end

    describe 'as a teacher' do
      it 'disables not selected exercises' do
        post :set_disabled_statuses, params: { course: { exercises: [@ex2.id] }, organization_id: @organization.slug, course_id: @course.id }
        @ex1.reload
        @ex2.reload
        @ex3.reload
        expect(@ex1.enabled?).to eq(false)
        expect(@ex2.enabled?).to eq(true)
        expect(@ex3.enabled?).to eq(false)
      end

      it 'enables all selected' do
        @ex3.disabled!
        post :set_disabled_statuses, params: { course: { exercises: [@ex1.id, @ex2.id, @ex3.id] }, organization_id: @organization.slug, course_id: @course.id }
        @ex1.reload
        @ex2.reload
        @ex3.reload
        expect(@ex1.enabled?).to eq(true)
        expect(@ex2.enabled?).to eq(true)
        expect(@ex3.enabled?).to eq(true)
      end

      it 'does not fail if no parameters are given' do
        expect do
          post :set_disabled_statuses, params: { course: { exercises: [] }, organization_id: @organization.slug, course_id: @course.id }
        end.to_not raise_error
      end
    end
  end
end
