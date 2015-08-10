require 'spec_helper'

describe CourseTemplatesController, type: :controller do
  before(:each) do
    @user = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
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
        FactoryGirl.create :course_template, name: 'template1'
        FactoryGirl.create :course_template, name: 'template2'
        FactoryGirl.create :course_template, name: 'template3'
      end
      it 'should show course templates' do
        get :index, {}
        expect(assigns(:course_templates).map(&:name)).to eq(%w(template1 template2 template3))
      end
    end

    describe 'GET edit' do
      before :each do
        @course_template = FactoryGirl.create :course_template, name: 'template'
      end

      it 'should show course template' do
        get :edit, id: @course_template.to_param
        expect(assigns(:course_template).name).to eq('template')
      end
    end

    describe 'POST create' do
      describe 'with valid params' do
        it 'creates a new course template' do
          expect do
            post :create, course_template: valid_attributes
          end.to change(CourseTemplate, :count).by(1)
          expect(CourseTemplate.last.name).to eq('TestTemplateCourse')
        end

        it 'redirects to the course templates list' do
          post :create, course_template: valid_attributes
          expect(response).to redirect_to(course_templates_url)
        end
      end

      describe 'with invalid params' do
        it "doesn't create any course templates" do
          expect do
            post :create, course_template: invalid_attributes
          end.to change(CourseTemplate, :count).by(0)
        end

        it "re-renders the 'new' template" do
          post :create, course_template: invalid_attributes
          expect(response).to render_template('new')
        end
      end
    end

    describe 'PUT update' do
      before :each do
        @course_template = FactoryGirl.create :course_template, name: 'oldName'
      end

      describe 'with valid params' do
        it 'updates the course template' do
          put :update, id: @course_template.to_param, course_template: valid_attributes
          expect(CourseTemplate.last.name).to eq('TestTemplateCourse')
        end

        it 'redirects to the course templates list' do
          put :update, id: @course_template.to_param, course_template: valid_attributes
          expect(response).to redirect_to(course_templates_url)
        end
      end

      describe 'with invalid params' do
        it "doesn't update the course template" do
          put :update, id: @course_template.to_param, course_template: invalid_attributes
          expect(CourseTemplate.last.name).to eq('oldName')
        end

        it "re-renders the 'edit' template" do
          put :update, id: @course_template.to_param, course_template: invalid_attributes
          expect(response).to render_template('edit')
        end
      end
    end

    describe 'DELETE destroy' do
      before :each do
        @course_template = FactoryGirl.create :course_template, name: 'oldName'
      end

      it 'destroys course template' do
        expect do
          delete :destroy, id: @course_template.to_param
        end.to raise_exception
      end
    end

    describe 'POST toggle_hidden' do
      it 'changes course templates visibility' do
        @course_template = FactoryGirl.create :course_template, name: 'template', hidden: false
        post :toggle_hidden, id: @course_template.to_param
        expect(CourseTemplate.last.hidden).to be(true)
      end
    end
  end

  describe 'when non admin' do
    before :each do
      controller.current_user = @user
    end

    describe 'GET index' do
      it 'should respond with a 401' do
        get :index, {}
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'GET edit' do
      before :each do
        @course_template = FactoryGirl.create :course_template
      end

      it 'should respond with a 401' do
        get :edit, id: @course_template.to_param
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'GET new' do
      it 'should respond with a 401' do
        get :new, {}
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'GET edit' do
      before :each do
        @course_template = FactoryGirl.create :course_template
      end

      it 'should respond with a 401' do
        get :edit, id: @course_template.to_param
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'POST create' do
      it "doesn't create any course templates" do
        expect do
          post :create, course_template: valid_attributes
        end.to change(CourseTemplate, :count).by(0)
      end

      it 'should respond with a 401' do
        post :create, course_template: valid_attributes
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'PUT update' do
      before :each do
        @course_template = FactoryGirl.create :course_template, name: 'oldName'
      end

      it "doesn't update the course template" do
        put :update, id: @course_template.to_param, course_template: invalid_attributes
        expect(CourseTemplate.last.name).to eq('oldName')
      end

      it 'should respond with a 401' do
        put :update, id: @course_template.to_param, course_template: invalid_attributes
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'DELETE destroy' do
      before :each do
        @course_template = FactoryGirl.create :course_template, name: 'oldName'
      end

      it "doesn't destroy the course template" do
        expect do
          delete :destroy, id: @course_template.to_param
        end.to change(CourseTemplate, :count).by(0)
      end

      it 'should respond with a 401' do
        delete :destroy, id: @course_template.to_param
        expect(response.code.to_i).to eq(401)
      end
    end
  end

  describe 'when guest' do
    before :each do
      controller.current_user = @guest
    end

    describe 'GET index' do
      it 'should respond with a 401' do
        get :index, {}
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'GET edit' do
      before :each do
        @course_template = FactoryGirl.create :course_template
      end

      it 'should respond with a 401' do
        get :edit, id: @course_template.to_param
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'GET new' do
      it 'should respond with a 401' do
        get :new, {}
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'GET edit' do
      before :each do
        @course_template = FactoryGirl.create :course_template
      end

      it 'should respond with a 401' do
        get :edit, id: @course_template.to_param
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'POST create' do
      it "doesn't create any course templates" do
        expect do
          post :create, course_template: valid_attributes
        end.to change(CourseTemplate, :count).by(0)
      end

      it 'should respond with a 401' do
        post :create, course_template: valid_attributes
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'PUT update' do
      before :each do
        @course_template = FactoryGirl.create :course_template, name: 'oldName'
      end

      it "doesn't update the course template" do
        put :update, id: @course_template.to_param, course_template: invalid_attributes
        expect(CourseTemplate.last.name).to eq('oldName')
      end

      it 'should respond with a 401' do
        put :update, id: @course_template.to_param, course_template: invalid_attributes
        expect(response.code.to_i).to eq(401)
      end
    end

    describe 'DELETE destroy' do
      before :each do
        @course_template = FactoryGirl.create :course_template, name: 'oldName'
      end

      it "doesn't destroy the course template" do
        expect do
          delete :destroy, id: @course_template.to_param
        end.to change(CourseTemplate, :count).by(0)
      end

      it 'should respond with a 401' do
        delete :destroy, id: @course_template.to_param
        expect(response.code.to_i).to eq(401)
      end
    end
  end

  describe 'when teacher' do
    before :each do
      controller.current_user = @user
      @organization = FactoryGirl.create(:accepted_organization)
      Teachership.create!(user: @user, organization: @organization)
    end

    describe 'GET list_for_teachers' do
      before :each do
        FactoryGirl.create :course_template, name: 'template1'
        FactoryGirl.create :course_template, name: 'template2'
        FactoryGirl.create :course_template, name: 'template3'
      end

      it 'should show course templates' do
        get :list_for_teachers, organization_id: @organization.slug
        expect(assigns(:course_templates).map(&:name)).to eq(%w(template1 template2 template3))
      end
    end
  end

  describe 'when non-teacher' do
    before :each do
      controller.current_user = @user
      @organization = FactoryGirl.create(:accepted_organization)
      @template = FactoryGirl.create :course_template
    end

    describe 'GET list_for_teachers' do
      it 'should respond with a 401' do
        get :list_for_teachers, organization_id: @organization.slug
        expect(response.code.to_i).to eq(401)
      end
    end
  end
end
