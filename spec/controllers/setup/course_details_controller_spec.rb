# frozen_string_literal: true

require 'spec_helper'

describe Setup::CourseDetailsController, type: :controller do
  include GitTestActions

  before :each do
    @organization = FactoryBot.create(:accepted_organization)
    @teacher = FactoryBot.create(:user)
    @user = FactoryBot.create(:user)
    @admin = FactoryBot.create(:admin)
    Teachership.create!(user: @teacher, organization: @organization)

    @ct = FactoryBot.create(:course_template)

    @source_path = "#{@test_tmp_dir}/fake_source"
    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    @source_url = "file://#{@source_path}"
    create_bare_repo(@repo_path)

    @course = FactoryBot.create(:course,
                                 organization: @organization,
                                 name: 'originalCourse',
                                 title: 'originalTitle',
                                 description: 'originalDescription',
                                 material_url: 'http://originalMaterial.com')
  end

  describe 'As organization teacher' do
    before :each do
      controller.current_user = @teacher
    end

    describe 'GET new' do
      it 'should create new course object from template' do
        get :new, params: { organization_id: @organization.slug, template_id: @ct.id }
        expect(assigns(:course).organization).to eq(@organization)
        expect(assigns(:course).name).to eq(@ct.name)
        expect(assigns(:course).source_url).to eq(@ct.source_url)
      end
    end

    describe 'POST create' do
      describe 'with valid parameters' do
        it 'should create a course' do
          init_session
          expect do
            post :create, params: { organization_id: @organization.slug, course: { name: 'NewCourse', title: 'New Course', course_template_id: @ct.id } }
          end.to change { Course.count }.by(1)
          expect(Course.last.initial_refresh_ready).to be_falsey
        end

        it 'redirects to the created course' do
          post :create, params: { organization_id: @organization.slug, course: { name: 'NewCourse', title: 'New Course', course_template_id: @ct.id } }
          expect(response).to redirect_to(setup_organization_course_course_timing_path(@organization, Course.last))
        end

        it "does directory changes when course is first created from template, but doesn't do changes when creating more courses from same template" do
          dummy_user = FactoryBot.create(:admin)
          expect(CourseTemplate.last.dummy).to be true
          expect(CourseTemplate.last.cached_version).to eq(0)
          post :create, params: { organization_id: @organization.slug, course: { name: 'NewCourse', title: 'New Course', course_template_id: @ct.id } }
          ImitateBackgroundRefresh.new.refresh(Course.last.course_template, dummy_user)
          expect(Course.all.order(:id).pluck(:cached_version)).to eq([0, 1])

          expect(CourseTemplate.find(@ct.id).cached_version).to eq(1)
          post :create, params: { organization_id: @organization.slug, course: { name: 'NewCourse2', title: 'New Course 2', course_template_id: @ct.id } }
          expect(Course.all.order(:id).pluck(:cached_version)).to eq([0, 1, 1])
          expect(CourseTemplate.find(@ct.id).cached_version).to eq(1)
          expect(Dir["#{@test_tmp_dir}/cache/git_repos/*"].count).to be(1)
        end
      end

      ## TODO: Refactor old course_controller setup tests here

      describe 'with invalid parameters' do
        it 'should not create a course' do
          post :create, params: { organization_id: @organization.slug, course: { name: 's p a c e s', title: 'New Course', source_url: @repo_path } }
          expect(response).to render_template(:new)
          expect(assigns(:course).name).to eq('s p a c e s')
        end
      end
    end

    describe 'GET edit' do
      describe 'when in wizard mode' do
        it 'should fill setup wizard bar' do
          init_session
          get :edit, params: { organization_id: @organization.slug, course_id: @course.id }
          expect(assigns(:course_setup_phases)).not_to be_nil
        end
      end

      describe 'when editing without wizard' do
        it 'should not fill setup wizard bar' do
          get :edit, params: { organization_id: @organization.slug, course_id: @course.id }
          expect(assigns(:course_setup_phases)).to be_nil
        end
      end
    end

    describe 'PUT update' do
      it 'should save the updates' do
        @new_repo_path = @test_tmp_dir + '/new_fake_remote_repo'
        create_bare_repo(@new_repo_path)
        put :update, params: { organization_id: @organization.slug, course_id: @course.id,
                     course: {
                       title: 'New title',
                       description: 'New description',
                       material_url: 'http://new.url',
                       source_url: @new_repo_path
                     } }
        course = Course.find @course.id
        expect(course.title).to eq('New title')
        expect(course.description).to eq('New description')
        expect(course.material_url).to eq('http://new.url')
        expect(course.source_url).to eq(@new_repo_path)
      end

      describe 'when in wizard mode' do
        it 'redirects to next wizard page' do
          init_session
          put :update, params: { organization_id: @organization.slug, course_id: @course.id,
                       course: { title: 'New title', description: 'New description', material_url: 'http://new.url' } }
          expect(response).to redirect_to(setup_organization_course_course_timing_path(@organization, Course.find(@course.id)))
        end
      end

      describe 'when updating without wizard' do
        it 'redirects to course page' do
          put :update, params: { organization_id: @organization.slug, course_id: @course.id,
                       course: { title: 'New title', description: 'New description', material_url: 'http://new.url' } }
          expect(response).to redirect_to(organization_course_path(@organization, Course.find(@course.id)))
        end
      end

      describe 'with invalid parameters' do
        it 'renders form again with invalid parameters' do
          post :update, params: { organization_id: @organization.to_param, course_id: @course.to_param,
                        course: { title: 'a' * 81 } }
          expect(response).to render_template('edit')
        end

        it "can't update course name" do
          put :update, params: { organization_id: @organization.to_param, course_id: @course.to_param,
                       course: { name: 'newName' } }
          expect(Course.last.name).to eq('originalCourse')
        end

        it "can't update course template id" do
          old_id = @course.course_template_id
          put :update, params: { organization_id: @organization.to_param, course_id: @course.to_param,
                       course: { course_template_id: 2 } }
          expect(Course.last.course_template_id).to eq(old_id)
        end
      end

      describe 'when course created from template' do
        before :each do
          @course.course_template = @ct
          @course.source_url = @ct.source_url
          @course.save!
        end

        it "can't update source_url" do
          @new_repo_path = @test_tmp_dir + '/new_fake_remote_repo'
          create_bare_repo(@new_repo_path)
          put :update, params: { organization_id: @organization.to_param, course_id: @course.to_param,
                       course: { source_url: @new_repo_path } }
          expect(Course.last.source_url).to eq(@ct.source_url)
        end

        it "can't update git_branch" do
          put :update, params: { organization_id: @organization.to_param, course_id: @course.to_param,
                       course: { git_branch: 'ufobranch' } }
          expect(Course.last.git_branch).to eq('master')
        end
      end

      it 'should not update without teacher permissions' do
        controller.current_user = @user
        put :update, params: { organization_id: @organization.to_param, course_id: @course.to_param,
                     course: { title: 'newTitle', description: 'newDescription', material_url: 'http://newMaterial.com' } }
        course = Course.last
        expect(course.title).to eq('originalTitle')
        expect(course.description).to eq('originalDescription')
        expect(course.material_url).to eq('http://originalMaterial.com')
      end
    end

    ## TODO: Tests for the rest of the actions, when they are properly implemented
  end

  describe 'As admin' do
    before :each do
      controller.current_user = @admin
    end

    describe 'when creating custom course' do
      it 'should create the course' do
        init_session
        expect do
          post :create, params: { organization_id: @organization.slug, course: { name: 'NewCourse', title: 'New Course', source_url: @repo_path } }
        end.to change { Course.count }.by(1)
      end

      it 'does directory changes via refresh' do
        post :create, params: { organization_id: @organization.slug, course: { name: 'NewCourse', title: 'New Course', source_url: @ct.source_url } }
        ImitateBackgroundRefresh.new.refresh(Course.last.course_template, @admin)
        expect(Course.last.cached_version).to eq(1)
        post :create, params: { organization_id: @organization.slug, course: { name: 'NewCourse2', title: 'New Course 2', source_url: @ct.source_url } }
        ImitateBackgroundRefresh.new.refresh(Course.last.course_template, @admin)
        expect(Course.all.pluck(:cached_version)).to eq([0, 1, 1])
        expect(Dir["#{@test_tmp_dir}/cache/git_repos/*"].count).to be(2)
      end
    end
  end

  describe 'As non-teacher' do
    before :each do
      controller.current_user = @user
    end

    it 'should not allow any access' do
      get :new, params: { organization_id: @organization.slug, template_id: @ct.id }
      expect(response.code.to_i).to eq(403)
      post :create, params: { organization_id: @organization.slug, course: { name: 'NewCourse', title: 'New Course', source_url: @repo_path, course_template_id: @ct.id } }
      expect(response.code.to_i).to eq(403)
      ## TODO: Rest of the actions
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
