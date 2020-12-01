# frozen_string_literal: true

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

  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
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
        get :download, id: 123_456
        expect(response.code).to eq('404')
      end
    end
  end

  describe 'When logged in' do
    let(:token) { double resource_owner_id: user.id, acceptable?: true }
    describe 'and correct exercise id is given' do
      it 'should return correct data' do
        submission = FactoryGirl.create(:submission, course: course, user: user, exercise: exercise)
        get :show, id: exercise.id
        expect(response.body).to include course.name
        expect(response.body).to include 'submissions'
        expect(response.body).to include "http://test.host/api/v8/core/submissions/#{submission.id}/download"
      end
    end
    describe 'and invalid exercise id is given' do
      it 'should show appropriate error' do
        get :show, id: 741
        expect(response).to have_http_status :not_found
        expect(response.body).to include "Couldn't find Exercise with 'id'=741"
      end
    end
  end

  describe 'When unauthenticated' do
    let(:current_user) { Guest.new }
    let(:token) { nil }
    it 'should show authentication error' do
      get :show, id: exercise.id
      expect(response).to have_http_status :unauthorized
      expect(response.body).to include 'Authentication required'
    end
  end

  after :all do
    FileUtils.rm_rf(repo_path)
  end
end
