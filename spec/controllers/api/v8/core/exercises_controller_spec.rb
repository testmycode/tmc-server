require 'spec_helper'
require 'fileutils'

describe Api::V8::Core::ExercisesController, type: :controller do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let(:course_name) { 'testcourse' }
  repo_path = Dir.tmpdir + '/api/v8/core/exercises/remote_repo'
  FileUtils.rm_rf(repo_path)
  create_bare_repo(repo_path)
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-#{course_name}", organization: organization, source_backend: 'git', source_url: repo_path) }
  let!(:exercise) { FactoryGirl.create(:exercise, course: course) }
  let!(:submission) { FactoryGirl.create(:submission, course: course, user: user, exercise: exercise)}

  before :each do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'Downloading an exercise zip' do
    describe 'as any user' do
      let(:current_user) { Guest.new }
      let(:token) { nil }

      it 'should succeed if the exercise exists' do
        exercise_name = 'zipexercise'
        repo = clone_course_repo(course)
        repo.copy_simple_exercise(exercise_name)
        repo.add_commit_push
        course.refresh

        get :download, id: Exercise.find_by(name: exercise_name).id
        expect(response).to have_http_status :ok
        File.open('zipexercise.zip', 'wb') { |f| f.write(response.body) }
        system!('unzip -qq zipexercise.zip')
        expect(File).to be_a_directory('zipexercise')
        expect(File).to exist('zipexercise/src/SimpleStuff.java')
      end
      it "should fail if the exercise doesn't exist" do
        get :download, id: 123456
        expect(response.code).to eq('404')
      end
    end
  end

  after :all do
    FileUtils.rm_rf(repo_path)
  end
end