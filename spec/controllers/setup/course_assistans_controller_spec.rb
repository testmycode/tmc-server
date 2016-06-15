require 'spec_helper'

describe Setup::CourseAssistantsController, type: :controller do

  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @course = FactoryGirl.create(:course, organization: @organization)
    @teacher = FactoryGirl.create(:user)
    @user = FactoryGirl.create(:user)
    @assistant = FactoryGirl.create(:user, login: 'assi')
    Teachership.create!(user: @teacher, organization: @organization)
  end

  describe 'As organization teacher' do
    before :each do
      controller.current_user = @teacher
    end

    describe 'post CREATE' do
      it 'creates a new assistant' do
        expect(@course.assistants.count).to eq(0)
        post :create, {
             organization_id: @organization.slug,
             course_id: @course.id,
             commit: 'Add new assistant',
             username: 'assi'
        }
        expect(assigns(:course).assistants.first).to eq(@assistant)
      end

      it 'does not create assistant if user not found' do
        expect(@course.assistants.count).to eq(0)
        post :create, {
            organization_id: @organization.slug,
            course_id: @course.id,
            commit: 'Add new assistant',
            username: 'notfound'
        }
        expect(@course.assistants.count).to eq(0)
        expect(response).to render_template(:index)
      end

      it 'continues to next step' do
        post :create, {organization_id: @organization.slug, course_id: @course.id}
        expect(response).to redirect_to(setup_organization_course_course_finisher_index_path)
      end
    end
  end

  describe 'As non-teacher' do
    before :each do
      controller.current_user = @user
    end

    it 'should not allow any access' do
      get :index, {organization_id: @organization.slug, course_id: @course.id}
      expect(response.code.to_i).to eq(401)
      post :create, {
          organization_id: @organization.slug,
          course_id: @course.id,
          commit: 'Add new assistant',
          username: 'assi'
      }
      expect(response.code.to_i).to eq(401)
    end
  end
end
