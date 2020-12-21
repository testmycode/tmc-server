# frozen_string_literal: true

require 'spec_helper'

describe CoursesController, type: :controller do
  include GitTestActions

  before(:each) do
    @source_path = "#{@test_tmp_dir}/fake_source"
    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    @source_url = "file://#{@source_path}"
    create_bare_repo(@repo_path)
    @user = FactoryGirl.create(:user)
    @teacher = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
    @organization = FactoryGirl.create(:accepted_organization)
    Teachership.create(user: @teacher, organization: @organization)
  end

  describe 'GET index' do
    it 'shows visible courses in order by name, split into ongoing and expired' do
      get :index, params: { organization_id: @organization.slug }
      expect(response.code.to_i).to eq(302)
      expect(response).to redirect_to(organization_path(@organization))
    end

    describe 'in JSON format' do
      def get_index_json(options = {})
        options = {
          format: 'json',
          api_version: ApiVersion::API_VERSION,
          organization_id: @organization.slug
        }.merge options
        @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64.encode64("#{@user.login}:#{@user.password}")
        get :index, params: options
        JSON.parse(response.body)
      end

      it 'renders all non-hidden courses in order by name' do
        FactoryGirl.create(:course, name: 'Course1', organization: @organization)
        FactoryGirl.create(:course, name: 'Course2', organization: @organization, hide_after: Time.now + 1.week)
        FactoryGirl.create(:course, name: 'Course3', organization: @organization)
        FactoryGirl.create(:course, name: 'ExpiredCourse', hide_after: Time.now - 1.week)
        FactoryGirl.create(:course, name: 'HiddenCourse', hidden: true)

        result = get_index_json

        expect(result['courses'].map { |c| c['name'] }).to eq(%w[Course1 Course2 Course3])
      end
    end
  end

  describe 'GET show' do
    before :each do
      @course = FactoryGirl.create(:course)
    end

    describe 'for administrators' do
      before :each do
        controller.current_user = @admin
      end

      it "should show everyone's submissions" do
        user1 = FactoryGirl.create(:user)
        user2 = FactoryGirl.create(:user)
        sub1 = FactoryGirl.create(:submission, user: user1, course: @course)
        sub2 = FactoryGirl.create(:submission, user: user2, course: @course)

        get :show, params: { organization_id: @organization.slug, id: @course.id }

        expect(assigns['submissions']).to include(sub1)
        expect(assigns['submissions']).to include(sub2)
      end
    end

    describe 'for guests' do
      before :each do
        controller.current_user = Guest.new
      end

      it 'should show no submissions' do
        FactoryGirl.create(:submission, course: @course)
        FactoryGirl.create(:submission, course: @course)

        get :show, params: { organization_id: @organization.slug, id: @course.id }

        expect(assigns['submissions']).to be_nil
      end
    end

    describe 'for regular users' do
      before :each do
        controller.current_user = @user
      end
      it "should show only the current user's submissions" do
        other_user = FactoryGirl.create(:user)
        my_sub = FactoryGirl.create(:submission, user: @user, course: @course)
        other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: @course)

        get :show, params: { organization_id: @organization.slug, id: @course.id }

        expect(assigns['submissions']).to include(my_sub)
        expect(assigns['submissions']).not_to include(other_guys_sub)
      end
    end

    describe 'in JSON format' do
      before :each do
        @course = FactoryGirl.create(:course, name: 'Course1')
        @course.exercises << FactoryGirl.create(:returnable_exercise, name: 'Exercise1', course: @course)
        @course.exercises << FactoryGirl.create(:returnable_exercise, name: 'Exercise2', course: @course)
        @course.exercises << FactoryGirl.create(:returnable_exercise, name: 'Exercise3', course: @course)
      end

      def get_show_json(options = {}, parse_json = true)
        options = {
          format: 'json',
          api_version: ApiVersion::API_VERSION,
          id: @course.id.to_s,
          organization_id: @organization.slug
        }.merge options
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, @user.password)
        get :show, params: options
        if parse_json
          JSON.parse(response.body)
        else
          response.body
        end
      end

      it 'should render the exercises for each course' do
        result = get_show_json

        exs = result['course']['exercises']
        expect(exs[0]['name']).to eq('Exercise1')
        expect(exs[1]['name']).to eq('Exercise2')
        expect(exs[0]['zip_url']).to eq(exercise_url(@course.exercises[0].id, format: 'zip'))
        expect(exs[0]['return_url']).to eq(exercise_submissions_url(@course.exercises[0].id, format: 'json'))
      end

      it 'should include only visible exercises' do
        @course.exercises[0].hidden = true
        @course.exercises[0].save!
        @course.exercises[1].deadline_spec = [Date.yesterday.to_s].to_json
        @course.exercises[1].save!

        result = get_show_json

        names = result['course']['exercises'].map { |ex| ex['name'] }
        expect(names).not_to include('Exercise1')
        expect(names).to include('Exercise2')
        expect(names).to include('Exercise3')
      end

      it "should tell each the exercise's deadline" do
        @course.exercises[0].deadline_spec = [Time.zone.parse('2011-11-16 23:59:59+0200').to_s].to_json
        @course.exercises[0].save!

        result = get_show_json

        expect(result['course']['exercises'][0]['deadline']).to eq('2011-11-16T23:59:59.000+02:00')
      end

      it 'should tell for each exercise whether it has been attempted' do
        sub = FactoryGirl.create(:submission, course: @course, exercise: @course.exercises[0], user: @user)
        FactoryGirl.create(:test_case_run, submission: sub, successful: false)

        result = get_show_json

        exs = result['course']['exercises']
        expect(exs[0]['attempted']).to be_truthy
        expect(exs[1]['attempted']).to be_falsey
      end

      it 'should tell for each exercise whether it has been completed' do
        FactoryGirl.create(:submission, course: @course, exercise: @course.exercises[0], user: @user, all_tests_passed: true)

        result = get_show_json

        exs = result['course']['exercises']
        expect(exs[0]['completed']).to be_truthy
        expect(exs[1]['completed']).to be_falsey
      end

      describe 'and no user given' do
        it 'should respond with a 401' do
          controller.current_user = Guest.new
          get_show_json({ api_username: nil, api_password: nil }, false)
          expect(response.code.to_i).to eq(401)
        end
      end

      describe 'and the given user does not exist' do
        before :each do
          @user.destroy
        end

        it 'should respond with a 401' do
          get_show_json({}, false)
          expect(response.code.to_i).to eq(401)
        end
      end
    end
  end

  describe 'POST refresh' do
    before :each do
      controller.current_user = FactoryGirl.create :user
      Teachership.create user: controller.current_user, organization: @organization
      @template = FactoryGirl.create :course_template
    end

    it "can't refresh if course created from template" do
      @course = FactoryGirl.create :course, organization: @organization, course_template: @template, source_url: @template.source_url
      post :refresh, organization_id: @organization.slug, id: @course.id
      expect(response.code.to_i).to eq(403)
    end
  end

  describe 'POST disable' do
    before :each do
      @course = FactoryGirl.create(:course)
    end

    describe 'As a teacher' do
      it 'disables the course' do
        controller.current_user = @teacher
        post :disable, organization_id: @organization.slug, id: @course.id.to_s
        expect(Course.find(@course.id).disabled?).to eq(true)
      end
    end

    describe 'As a student' do
      it 'denies access' do
        controller.current_user = @user
        post :disable, organization_id: @organization.slug, id: @course.id.to_s
        expect(response.code.to_i).to eq(403)
      end
    end
  end

  describe 'POST enable' do
    before :each do
      @course = FactoryGirl.create(:course)
    end

    describe 'As a teacher' do
      it 'enables the course' do
        controller.current_user = @teacher
        post :enable, organization_id: @organization.slug, id: @course.id.to_s
        expect(Course.find(@course.id).disabled?).to eq(false)
      end
    end

    describe 'As a student' do
      it 'denies access' do
        controller.current_user = @user
        post :disable, organization_id: @organization.slug, id: @course.id.to_s
        expect(response.code.to_i).to eq(403)
      end
    end
  end

  describe 'POST save_deadlines' do
    before :each do
      @course = FactoryGirl.create :course, organization: @organization
      Teachership.create(user: @user, organization: @organization)
      controller.current_user = @user
    end

    it 'saves deadlines for courses in empty group (name: "")' do
      @course.exercises.create(name: 'e1')
      @course.exercises.create(name: 'e2')
      @course.exercises.create(name: 'e3')

      post :save_deadlines,
           organization_id: @organization.slug,
           id: @course.id,
           empty_group: {
             soft: { static: '1.1.2000', unlock: '' },
             hard: { static: '', unlock: 'unlock + 2 weeks' }
           }

      @course.exercise_group_by_name('').exercises(false).each do |e|
        expect(e.soft_static_deadline).to eq('1.1.2000')
        expect(e.soft_unlock_deadline).to be_nil
        expect(e.static_deadline).to be_nil
        expect(e.unlock_deadline).to eq('unlock + 2 weeks')
      end
    end

    it 'saves deadlines for courses in a group' do
      @course.exercises.create(name: 'group1-e1')
      @course.exercises.create(name: 'group1-e2')
      @course.exercises.create(name: 'group1-e3')
      @course.exercises.create(name: 'group2-e1')
      @course.exercises.create(name: 'group2-e2')

      post :save_deadlines,
           organization_id: @organization.slug,
           id: @course.id,
           group: {
             group1: {
               soft: { static: '1.1.2000', unlock: 'unlock + 7 days' },
               hard: { static: '', unlock: 'unlock + 2 months' }
             },
             group2: {
               soft: { static: '2.2.2000', unlock: '' },
               hard: { static: '3.3.2000', unlock: '' }
             }
           }

      @course.exercise_group_by_name('group1').exercises(false).each do |e|
        expect(e.soft_static_deadline).to eq('1.1.2000')
        expect(e.soft_unlock_deadline).to eq('unlock + 7 days')
        expect(e.static_deadline).to be_nil
        expect(e.unlock_deadline).to eq('unlock + 2 months')
      end

      @course.exercise_group_by_name('group2').exercises(false).each do |e|
        expect(e.soft_static_deadline).to eq('2.2.2000')
        expect(e.soft_unlock_deadline).to be_nil
        expect(e.static_deadline).to eq('3.3.2000')
        expect(e.unlock_deadline).to be_nil
      end
    end
  end

  describe 'GET manage_unlocks' do
    it 'when non-teacher should respond with a 403' do
      @course = FactoryGirl.create :course
      @course.organization = @organization
      controller.current_user = @user
      get :manage_unlocks, organization_id: @organization.slug, id: @course.id
      expect(response.code.to_i).to eq(403)
    end
  end

  describe 'POST save_unlocks' do
    before :each do
      @course = FactoryGirl.create :course, organization: @organization
      controller.current_user = @user
    end

    describe 'when teacher' do
      before :each do
        Teachership.create(user: @user, organization: @organization)
      end

      it 'saves unlock dates for exercises in group named ""' do
        @course.exercises.create(name: 'e1')
        @course.exercises.create(name: 'e2')
        @course.exercises.create(name: 'e3')

        post :save_unlocks, organization_id: @organization.slug, id: @course.id, empty_group: { '0' => '1.2.2000' }

        @course.exercise_group_by_name('').exercises(false).each do |e|
          expect(e.unlock_spec_obj.valid_after).to be_within(1.day).of Time.new(2000, 2, 1)
        end
      end

      it 'saves unlock dates for exercises in group named something else' do
        @course.exercises.create(name: 'group1-e1')
        @course.exercises.create(name: 'group1-e2')
        @course.exercises.create(name: 'group1-e3')
        @course.exercises.create(name: 'group2-e1')

        post :save_unlocks, organization_id: @organization.slug, id: @course.id, group: { group1: { '0' => '1.2.2000' } }

        @course.exercise_group_by_name('group1').exercises(false).each do |e|
          expect(e.unlock_spec_obj.valid_after).to be_within(1.day).of Time.new(2000, 2, 1)
        end
        @course.exercise_group_by_name('group2').exercises(false).each do |e|
          expect(e.unlock_spec_obj.valid_after).to be_nil
        end
      end

      it 'empty unlock date is acceptable' do
        @course.exercises.create(name: 'e1')
        @course.exercises.create(name: 'e2')
        @course.exercises.create(name: 'e3')

        post :save_unlocks, organization_id: @organization.slug, id: @course.id, empty_group: { 0 => '1.2.2000' }
        post :save_unlocks, organization_id: @organization.slug, id: @course.id, empty_group: { 0 => '' }

        @course.exercise_group_by_name('').exercises(false).each do |e|
          expect(e.unlock_spec_obj.valid_after).to be_nil
        end
      end

      it 'accepts and saves multiple unlock conditions' do
        @course.exercises.create(name: 'e1')
        @course.exercises.create(name: 'e2')
        @course.exercises.create(name: 'e3')

        post :save_unlocks, organization_id: @organization.slug, id: @course.id,
                            empty_group: { '0' => '1.2.2000', '1' => 'exercise e1', '2' => '5% of e2' }

        @course.exercise_group_by_name('').exercises(false).each do |e|
          spec = e.unlock_spec_obj.raw_spec
          expect(spec).to include('1.2.2000')
          expect(spec).to include('exercise e1')
          expect(spec).to include('5% of e2')
        end
      end
    end

    it 'when non-teacher should respond with a 403' do
      @course.exercises.create(name: 'e')
      post :save_unlocks, organization_id: @organization.slug, id: @course.id, empty_group: { 0 => '1.2.2000' }
      expect(response.code.to_i).to eq(403)
    end
  end

  describe 'POST toggle_submission_result_visibility' do
    before :each do
      @course = FactoryGirl.create :course, organization: @organization
    end

    describe 'when teacher' do
      it 'toggles visibility of submsission results' do
        controller.current_user = @teacher
        post :toggle_submission_result_visibility, organization_id: @organization.slug, id: @course.id
        @course.reload
        expect(@course.hide_submission_results).to be true
        expect(response).to redirect_to(organization_course_path)
      end
    end

    describe 'when the assistant of the course' do
      it 'toggles visibility of submsission results' do
        Assistantship.create(user: @user, course: @course)
        controller.current_user = @user
        post :toggle_submission_result_visibility, organization_id: @organization.slug, id: @course.id
        @course.reload
        expect(@course.hide_submission_results).to be true
        expect(response).to redirect_to(organization_course_path)
      end
    end

    describe 'when non-teacher or non-admin' do
      it 'acces denied' do
        controller.current_user = @user
        post :toggle_submission_result_visibility, organization_id: @organization.slug, id: @course.id
        @course.reload
        expect(response.code.to_i).to eq(403)
      end
    end
  end
end
