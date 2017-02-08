require 'spec_helper'

describe Api::V8::Core::SubmissionsController, type: :controller do
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  repo_path = Dir.tmpdir + '/api/v8/core/submissions/remote_repo'
  FileUtils.rm_rf(repo_path)
  create_bare_repo(repo_path)
  let!(:course) { FactoryGirl.create(:course, organization: organization, source_backend: 'git', source_url: repo_path) }
  let!(:admin) { FactoryGirl.create(:admin) }
  let!(:teacher) { FactoryGirl.create(:user) }
  let!(:assistant) { FactoryGirl.create(:user) }
  let!(:user) { FactoryGirl.create(:user) }
  let!(:exercise) { FactoryGirl.create(:exercise, course: course) }
  let!(:submission) do
    FactoryGirl.create(:submission,
                       course: course,
                       user: user,
                       exercise: exercise)
  end
  let!(:submission_data) { FactoryGirl.create(:submission_data, submission: submission) }

  before :each do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'Downloading a submission as zip' do
    describe 'as an admin' do
      let(:token) { double resource_owner_id: admin.id, acceptable?: true }

      it "should allow to download everyone's submissions" do
        pending("test that submission zip's content is correct")
        get :download, id: submission.id
        expect(response.code).to eq('200')
        fail 'pending'
      end
    end
    describe 'as a teacher' do
      before :each do
        Teachership.create(user: teacher, organization: organization)
      end
      let(:token) { double resource_owner_id: teacher.id, acceptable?: true }

      it "should allow to download own organization's submissions" do
        pending("test that submission zip's content is correct")
        get :download, id: submission.id
        expect(response.code).to eq('200')
        fail 'pending'
      end
      it "should not allow to download other organizations' submissions" do
        other_organization = FactoryGirl.create(:accepted_organization)
        other_course = FactoryGirl.create(:course, organization: other_organization)
        other_exercise = FactoryGirl.create(:exercise, course: other_course)
        other_user = FactoryGirl.create(:user)
        other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

        get :download, id: other_guys_sub.id
        expect(response.code).to eq('403')
      end
    end
    describe 'as an assistant' do
      before :each do
        Assistantship.create(user: assistant, course: course)
      end
      let(:token) { double resource_owner_id: assistant.id, acceptable?: true }

      it "should allow to download own course's submissions" do
        pending("test that submission zip's content is correct")
        get :download, id: submission.id
        expect(response.code).to eq('200')
        fail 'pending'
      end
      it "should not allow to download other courses' submissions" do
        other_course = FactoryGirl.create(:course, organization: organization)
        other_exercise = FactoryGirl.create(:exercise, course: other_course)
        other_user = FactoryGirl.create(:user)
        other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

        get :download, id: other_guys_sub.id
        expect(response.code).to eq('403')
      end
    end
    describe 'as a student' do
      let(:token) { double resource_owner_id: user.id, acceptable?: true }

      it 'should allow to download own submissions' do
        pending("test that submission zip's content is correct")
        get :download, id: submission.id
        expect(response.code).to eq('200')
        fail 'pending'
      end
      it "should not allow to download other students' submissions" do
        other_course = FactoryGirl.create(:course, organization: organization)
        other_exercise = FactoryGirl.create(:exercise, course: other_course)
        other_user = FactoryGirl.create(:user)
        other_guys_sub = FactoryGirl.create(:submission, user: other_user, course: other_course, exercise: other_exercise)

        get :download, id: other_guys_sub.id
        expect(response.code).to eq('403')
      end
    end
    describe 'as an unauthenticated user' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      it 'should not allow downloading' do
        get :download, id: submission.id
        expect(response.code).to eq('403')
      end
    end
  end

  after :all do
    FileUtils.rm_rf(repo_path)
  end
end
