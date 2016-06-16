require 'spec_helper'

describe Setup::CourseDetailsController, type: :controller do
  include GitTestActions

  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @teacher = FactoryGirl.create(:user)
    @user = FactoryGirl.create(:user)
    Teachership.create!(user: @teacher, organization: @organization)
    @ct = FactoryGirl.create(:course_template)

    @source_path = "#{@test_tmp_dir}/fake_source"
    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    @source_url = "file://#{@source_path}"
    create_bare_repo(@repo_path)

  end

  describe 'As organization teacher' do
    before :each do
      controller.current_user = @teacher
    end

    describe 'GET new' do
      it 'should create new course object from template' do
        get :new, {organization_id: @organization.slug, template_id: @ct.id}
        expect(assigns(:course).organization).to eq(@organization)
        expect(assigns(:course).name).to eq(@ct.name)
        expect(assigns(:course).source_url).to eq(@ct.source_url)
      end
    end

    describe 'POST create' do
      describe 'with valid parameters' do
        it 'should create a course' do
          expect do
            post :create, organization_id: @organization.slug, course: { name: 'NewCourse', title: 'New Course', source_url: @repo_path, course_template_id: @ct.id }
          end.to change { Course.count }.by(1)
        end
      end

      ## TODO: Refactor old course_controller setup tests here

      describe 'with invalid parameters' do
        it 'should not create a course' do
          post :create, organization_id: @organization.slug, course: { name: 's p a c e s', title: 'New Course', source_url: @repo_path }
          expect(response).to render_template(:new)
          expect(assigns(:course).name).to eq('s p a c e s')
        end
      end
    end
    ## TODO: Tests for the rest of the actions, when they are properly implemented
  end

  describe 'As non-teacher' do
    before :each do
      controller.current_user = @user
    end

    it 'should not allow any access' do
      get :new, {organization_id: @organization.slug, template_id: @ct.id}
      expect(response.code.to_i).to eq(401)
      post :create, organization_id: @organization.slug, course: { name: 'NewCourse', title: 'New Course', source_url: @repo_path, course_template_id: @ct.id }
      expect(response.code.to_i).to eq(401)
      ## TODO: Rest of the actions
    end
  end
end
