# frozen_string_literal: true

require 'spec_helper'

describe CourseTemplatesController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user)
    @admin = FactoryBot.create(:admin)
    @guest = Guest.new

    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    create_bare_repo(@repo_path)
  end

  let(:valid_attributes) do
    {
      name: 'TestTemplateCourse',
      source_url: @repo_path,
      source_backend: 'git',
      git_branch: 'master',
      title: 'Test Template Title'
    }
  end

  let(:invalid_attributes) do
    {
      name: 'w h i t e s p a c e s',
      source_url: '',
      source_backend: 'txt',
      git_branch: 'nonexistent',
      title: 'a' * 41
    }
  end

  describe 'when admin' do
    before :each do
      controller.current_user = @admin
    end

    describe 'GET index' do
      before :each do
        FactoryBot.create :course_template, name: 'template1'
        FactoryBot.create :course_template, name: 'template2'
        FactoryBot.create :course_template, name: 'template3'
      end
      it 'should show course templates' do
        get :index, params: {}
        expect(assigns(:course_templates).map(&:name)).to eq(%w[template1 template2 template3])
      end
    end

    describe 'GET edit' do
      before :each do
        @course_template = FactoryBot.create :course_template, name: 'template'
      end

      it 'should show course template' do
        get :edit, params: { id: @course_template.to_param }
        expect(assigns(:course_template).name).to eq('template')
      end
    end

    describe 'POST create' do
      describe 'with valid params' do
        it 'creates a new course template' do
          expect do
            post :create, params: { course_template: valid_attributes }
          end.to change(CourseTemplate, :count).by(1)
          expect(CourseTemplate.last.name).to eq('TestTemplateCourse')
        end

        it 'redirects to the course templates list' do
          post :create, params: { course_template: valid_attributes }
          expect(response).to redirect_to(course_templates_url)
        end
      end

      describe 'with invalid params' do
        it "doesn't create any course templates" do
          expect do
            post :create, params: { course_template: invalid_attributes }
          end.to change(CourseTemplate, :count).by(0)
        end

        it "re-renders the 'new' template" do
          post :create, params: { course_template: invalid_attributes }
          expect(response).to render_template('new')
        end
      end
    end

    describe 'PUT update' do
      before :each do
        @course_template = FactoryBot.create :course_template, name: 'oldName'
      end

      describe 'with valid params' do
        it 'updates the course template' do
          put :update, params: { id: @course_template.to_param, course_template: valid_attributes }
          expect(CourseTemplate.last.name).to eq('TestTemplateCourse')
        end

        it 'redirects to the course templates list' do
          put :update, params: { id: @course_template.to_param, course_template: valid_attributes }
          expect(response).to redirect_to(course_templates_url)
        end
      end

      describe 'with invalid params' do
        it "doesn't update the course template" do
          put :update, params: { id: @course_template.to_param, course_template: invalid_attributes }
          expect(CourseTemplate.last.name).to eq('oldName')
        end

        it "re-renders the 'edit' template" do
          put :update, params: { id: @course_template.to_param, course_template: invalid_attributes }
          expect(response).to render_template('edit')
        end
      end
    end

    describe 'DELETE destroy' do
      before :each do
        @course_template = FactoryBot.create :course_template, name: 'oldName'
      end

      it 'destroys course template' do
        expect do
          delete :destroy, params: { id: @course_template.to_param }
        end.to raise_exception(RuntimeError, 'One does not destroy a course template')
      end
    end

    describe 'POST toggle_hidden' do
      it 'changes course templates visibility' do
        @course_template = FactoryBot.create :course_template, name: 'template', hidden: false
        post :toggle_hidden, params: { id: @course_template.to_param }
        expect(CourseTemplate.last.hidden).to be(true)
      end
    end
  end

  describe 'when non admin' do
    before :each do
      controller.current_user = @user
    end

    describe 'GET index' do
      it 'should respond with a 403' do
        get :index, params: {}
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'GET edit' do
      before :each do
        @course_template = FactoryBot.create :course_template
      end

      it 'should respond with a 403' do
        get :edit, params: { id: @course_template.to_param }
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'GET new' do
      it 'should respond with a 403' do
        get :new
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'GET edit' do
      before :each do
        @course_template = FactoryBot.create :course_template
      end

      it 'should respond with a 403' do
        get :edit, params: { id: @course_template.to_param }
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'POST create' do
      it "doesn't create any course templates" do
        expect do
          post :create, params: { course_template: valid_attributes }
        end.to change(CourseTemplate, :count).by(0)
      end

      it 'should respond with a 403' do
        post :create, params: { course_template: valid_attributes }
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'PUT update' do
      before :each do
        @course_template = FactoryBot.create :course_template, name: 'oldName'
      end

      it "doesn't update the course template" do
        put :update, params: { id: @course_template.to_param, course_template: invalid_attributes }
        expect(CourseTemplate.last.name).to eq('oldName')
      end

      it 'should respond with a 403' do
        put :update, params: { id: @course_template.to_param, course_template: invalid_attributes }
        expect(response.code.to_i).to eq(403)
      end
    end

    describe 'DELETE destroy' do
      before :each do
        @course_template = FactoryBot.create :course_template, name: 'oldName'
      end

      it "doesn't destroy the course template" do
        expect do
          delete :destroy, params: { id: @course_template.to_param }
        end.to change(CourseTemplate, :count).by(0)
      end

      it 'should respond with a 403' do
        delete :destroy, params: { id: @course_template.to_param }
        expect(response.code.to_i).to eq(403)
      end
    end
  end

  describe 'when guest' do
    before :each do
      controller.current_user = @guest
    end

    describe 'GET index' do
      it 'should respond with a 302 and redirect to login with correct return_to param' do
        get :index, params: {}
        expect(response.code.to_i).to eq(302)
        expect(response.headers['Location']).to include('/login?return_to=%2Fcourse_templates')
      end
    end

    describe 'GET edit' do
      before :each do
        @course_template = FactoryBot.create :course_template
      end

      it 'should respond with a 302 and redirect to login with correct return_to param' do
        get :edit, params: { id: @course_template.to_param }
        expect(response.code.to_i).to eq(302)
        expect(response.headers['Location']).to include('/login?return_to=%2Fcourse_templates')
      end
    end

    describe 'GET new' do
      it 'should respond with a 302 and redirect to login with correct return_to param' do
        get :new
        expect(response.code.to_i).to eq(302)
        expect(response.headers['Location']).to include('/login?return_to=%2Fcourse_templates')
      end
    end

    describe 'GET edit' do
      before :each do
        @course_template = FactoryBot.create :course_template
      end

      it 'should respond with a 302 and redirect to login with correct return_to param' do
        get :edit, params: { id: @course_template.to_param }
        expect(response.code.to_i).to eq(302)
        expect(response.headers['Location']).to include('/login?return_to=%2Fcourse_templates')
      end
    end

    describe 'POST create' do
      it "doesn't create any course templates" do
        expect do
          post :create, params: { course_template: valid_attributes }
        end.to change(CourseTemplate, :count).by(0)
      end

      it 'should respond with a 302 and redirect to login with correct return_to param' do
        post :create, params: { course_template: valid_attributes }
        expect(response.code.to_i).to eq(302)
        expect(response.headers['Location']).to include('/login?return_to=%2Fcourse_templates')
      end
    end

    describe 'PUT update' do
      before :each do
        @course_template = FactoryBot.create :course_template, name: 'oldName'
      end

      it "doesn't update the course template" do
        put :update, params: { id: @course_template.to_param, course_template: invalid_attributes }
        expect(CourseTemplate.last.name).to eq('oldName')
      end

      it 'should respond with a 302 and redirect to login with correct return_to param' do
        put :update, params: { id: @course_template.to_param, course_template: invalid_attributes }
        expect(response.code.to_i).to eq(302)
        expect(response.headers['Location']).to include('/login?return_to=%2Fcourse_templates')
      end
    end

    describe 'DELETE destroy' do
      before :each do
        @course_template = FactoryBot.create :course_template, name: 'oldName'
      end

      it "doesn't destroy the course template" do
        expect do
          delete :destroy, params: { id: @course_template.to_param }
        end.to change(CourseTemplate, :count).by(0)
      end

      it 'should respond with a 302 and redirect to login with correct return_to param' do
        delete :destroy, params: { id: @course_template.to_param }
        expect(response.code.to_i).to eq(302)
        expect(response.headers['Location']).to include('/login?return_to=%2Fcourse_templates')
      end
    end
  end

  describe 'when teacher' do
    before :each do
      controller.current_user = @user
      @organization = FactoryBot.create(:accepted_organization)
      Teachership.create!(user: @user, organization: @organization)
    end

    describe 'GET list_for_teachers' do
      before :each do
        FactoryBot.create :course_template, name: 'template1'
        FactoryBot.create :course_template, name: 'template2'
        FactoryBot.create :course_template, name: 'template3'
      end

      it 'should show course templates' do
        get :list_for_teachers, params: { organization_id: @organization.slug }
        expect(assigns(:course_templates).map(&:name)).to eq(%w[template1 template2 template3])
      end
    end
  end

  describe 'when non-teacher' do
    before :each do
      controller.current_user = @user
      @organization = FactoryBot.create(:accepted_organization)
      @template = FactoryBot.create :course_template
    end

    describe 'GET list_for_teachers' do
      it 'should respond with a 403' do
        get :list_for_teachers, params: { organization_id: @organization.slug }
        expect(response.code.to_i).to eq(403)
      end
    end
  end
end
