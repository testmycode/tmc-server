require 'spec_helper'

describe Api::V8::Core::SubmissionsController, type: :controller do
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  repo_path = Dir.tmpdir + '/submission182376/remote_repo'
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

  describe 'Creating a submission' do
    describe 'as an authenticated user' do
      it 'should accept submissions when the deadline is open' do
        pending("test that submission zip is accepted before deadline")
        fail
      end

      it 'should decline submissions when the deadline is closed' do
        pending("test that submission zip is declined after deadline")
        fail
      end

      it 'should decline submissions when the file is not ZIP' do
        pending("test that submission file is declined when not zip")
        fail
      end

      it 'should decline submissions when a file is not selected' do
        pending("test that submission is declined when no file is given")
        fail
      end
    end

    describe 'as an unauthenticated user' do
      it 'should not allow sending submission' do
        pending("test that submission is declined when no file is given")
        fail
      end
    end
  end
end
