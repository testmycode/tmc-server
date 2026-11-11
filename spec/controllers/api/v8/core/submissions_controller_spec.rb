# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Core::SubmissionsController, type: :controller do
  let!(:organization) { FactoryBot.create(:accepted_organization) }
  let(:repo_path) { Dir.tmpdir + '/api/v8/core/submissions/remote_repo' }

  before do
    FileUtils.rm_rf(repo_path)
    create_bare_repo(repo_path)
  end

  let!(:course) { FactoryBot.create(:course, organization: organization, source_backend: 'git', source_url: repo_path) }
  let!(:admin) { FactoryBot.create(:admin) }
  let!(:teacher) { FactoryBot.create(:user) }
  let!(:assistant) { FactoryBot.create(:user) }
  let!(:user) { FactoryBot.create(:user) }
  let!(:exercise) { FactoryBot.create(:exercise, course: course) }
  let!(:submission) do
    FactoryBot.create(:submission,
                       course: course,
                       user: user,
                       exercise: exercise)
  end
  let!(:submission_data) { FactoryBot.create(:submission_data, submission: submission) }

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  after do
    FileUtils.rm_rf(repo_path)
  end
  describe 'Downloading a submission as zip' do
    describe 'as an admin' do
      let(:token) { Doorkeeper::AccessToken.create!(resource_owner_id: admin.id, scopes: 'public') }

      it "should allow to download everyone's submissions" do
        # pending("test that submission zip's content is correct")
        get :download, params: { id: submission.id }
        expect(response.code).to eq('200')
        # raise 'pending'
      end
    end
    describe 'as a teacher' do
      before :each do
        Teachership.create(user: teacher, organization: organization)
      end
      let(:token) { Doorkeeper::AccessToken.create!(resource_owner_id: teacher.id, scopes: 'public') }

      it "should allow to download own organization's submissions" do
        # pending("test that submission zip's content is correct")
        get :download, params: { id: submission.id }
        expect(response.code).to eq('200')
        # raise 'pending'
      end
      it "should not allow to download other organizations' submissions" do
        other_organization = FactoryBot.create(:accepted_organization)
        other_course = FactoryBot.create(:course, organization: other_organization)
        other_exercise = FactoryBot.create(:exercise, course: other_course)
        other_user = FactoryBot.create(:user)
        other_guys_sub = FactoryBot.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

        get :download, params: { id: other_guys_sub.id }
        expect(response.code).to eq('403')
      end
    end
    describe 'as an assistant' do
      before :each do
        Assistantship.create(user: assistant, course: course)
      end
      let(:token) { Doorkeeper::AccessToken.create!(resource_owner_id: assistant.id, scopes: 'public') }

      it "should allow to download own course's submissions" do
        # pending("test that submission zip's content is correct")
        get :download, params: { id: submission.id }
        expect(response.code).to eq('200')
        # raise 'pending'
      end
      it "should not allow to download other courses' submissions" do
        other_course = FactoryBot.create(:course, organization: organization)
        other_exercise = FactoryBot.create(:exercise, course: other_course)
        other_user = FactoryBot.create(:user)
        other_guys_sub = FactoryBot.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

        get :download, params: { id: other_guys_sub.id }
        expect(response.code).to eq('403')
      end
    end
    describe 'as a student' do
      let(:token) { Doorkeeper::AccessToken.create!(resource_owner_id: user.id, scopes: 'public') }

      it 'should allow to download own submissions' do
        # pending("test that submission zip's content is correct")
        get :download, params: { id: submission.id }
        expect(response.code).to eq('200')
        # raise 'pending'
      end
      it "should not allow to download other students' submissions" do
        other_course = FactoryBot.create(:course, organization: organization)
        other_exercise = FactoryBot.create(:exercise, course: other_course)
        other_user = FactoryBot.create(:user)
        other_guys_sub = FactoryBot.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

        get :download, params: { id: other_guys_sub.id }
        expect(response.code).to eq('403')
      end
    end
    describe 'as an unauthenticated user' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      it 'should not allow downloading' do
        get :download, params: { id: submission.id }
        expect(response.code).to eq('401')
      end
    end
  end

  describe 'a submission whose exercise has been removed from the course' do
    let(:token) { Doorkeeper::AccessToken.create!(resource_owner_id: user.id, scopes: 'public') }

    before :each do
      exercise.update_column(:name, 'removed-by-refresh')
    end

    it 'can be downloaded' do
      get :download, params: { id: submission.id }
      expect(response.code).to eq('200')
    end

    it 'is shown without exercise details' do
      get :show, params: { id: submission.id }
      expect(response.code).to eq('200')
      json = response.parsed_body
      expect(json['exercise_name']).to eq(submission.exercise_name)
      expect(json['solution_url']).to be_nil
      expect(json['missing_review_points']).to eq([])
    end
  end

  describe 'a submission whose results are hidden' do
    let(:token) { Doorkeeper::AccessToken.create!(resource_owner_id: user.id, scopes: 'public') }

    before :each do
      course.update!(hide_submission_results: true)
    end

    it 'is shown as ok to a NetBeans plugin that sends no version' do
      get :show, params: { id: submission.id, client: 'netbeans_plugin' }
      expect(response.code).to eq('200')
      expect(response.parsed_body['status']).to eq('ok')
    end

    it 'is shown as ok to a NetBeans plugin older than 1.2.5' do
      get :show, params: { id: submission.id, client: 'netbeans_plugin', client_version: '1.2.4' }
      expect(response.parsed_body['status']).to eq('ok')
    end

    it 'is shown as hidden to a NetBeans plugin from 1.2.5 on' do
      get :show, params: { id: submission.id, client: 'netbeans_plugin', client_version: '1.2.5' }
      expect(response.parsed_body['status']).to eq('hidden')
    end
  end
end
