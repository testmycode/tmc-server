require 'spec_helper'
require 'fileutils'

describe Api::V8::Organizations::Courses::ExercisesController, type: :controller do
  let!(:organization) { FactoryGirl.create(:accepted_organization) }
  let(:course_name) { 'testcourse' }
  repo_path = Dir.tmpdir + '/api/v8/organizations/courses/exercises/remote_repo'
  FileUtils.rm_rf(repo_path)
  create_bare_repo(repo_path)
  let!(:course) { FactoryGirl.create(:course, name: "#{organization.slug}-#{course_name}", organization: organization, source_backend: 'git', source_url: repo_path) }
  let!(:exercise) { FactoryGirl.create(:exercise, name: 'testexercise', course: course) }
  let!(:hidden_exercise) { FactoryGirl.create(:exercise, name: 'hiddentestexercise', course: course, hidden: true) }
  let(:admin) { FactoryGirl.create(:admin, password: 'xooxer') }
  let(:user) { FactoryGirl.create(:user, login: 'user', password: 'xooxer') }

  before :each do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'As an admin' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when course name is given' do
      it 'should return successful response' do
        get :index, course_name: course_name, organization_slug: organization.slug
        expect(response).to have_http_status(:success)
      end
      it 'should return the courses exercises' do
        get :index, course_name: course_name, organization_slug: organization.slug
        expect(response.body).to have_content exercise.name
      end
      it 'should show hidden exercises' do
        get :index, course_name: course_name, organization_slug: organization.slug
        expect(response.body).to have_content hidden_exercise.name
      end
    end
  end

  describe 'As a student' do
    let(:token) { double resource_owner_id: user.id, acceptable?: true }
    describe 'when course name is given' do
      it 'should return successful response' do
        get :index, course_name: course_name, organization_slug: organization.slug
        expect(response).to have_http_status(:success)
      end
      it 'should return the courses exercises' do
        get :index, course_name: course_name, organization_slug: organization.slug
        expect(response.body).to have_content exercise.name
      end
      it 'should not show hidden exercises' do
        get :index, course_name: course_name, organization_slug: organization.slug
        expect(response.body).not_to have_content hidden_exercise.name
      end
    end
  end

  describe 'As any user' do
    let(:token) { double resource_owner_id: admin.id, acceptable?: true }
    describe 'when course name could not be found' do
      it 'should return error' do
        get :index, course_name: 'null', organization_slug: organization.slug
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'Downloading an exercise zip' do
    describe 'as an unauthenticated user' do
      let(:token) { double resource_owner_id: Guest.new.id, acceptable?: true }

      it 'should succeed if the course name and slug are correct', driver: :rack_test do
        repo = clone_course_repo(course)
        repo.copy_simple_exercise('zipexercise')
        repo.add_commit_push
        course.refresh

        visit "/api/v8/org/#{organization.slug}/courses/#{course_name}/exercises/zipexercise/download"
        File.open('zipexercise.zip', 'wb') { |f| f.write(page.source) }
        system!('unzip -qq zipexercise.zip')
        expect(File).to be_a_directory('zipexercise')
        expect(File).to exist('zipexercise/src/SimpleStuff.java')
      end
      it "should fail if the course name doesn't exist", driver: :rack_test do
        repo = clone_course_repo(course)
        repo.copy_simple_exercise('zipexercise2')
        repo.add_commit_push
        course.refresh

        visit "/api/v8/org/#{organization.slug}/courses/wrong_course_name/exercises/zipexercise2/download"
        expect(page.status_code).to be(404)
      end
      it "should fail if the oranization slug doesn't exist", driver: :rack_test do
        repo = clone_course_repo(course)
        repo.copy_simple_exercise('zipexercise3')
        repo.add_commit_push
        course.refresh

        visit "/api/v8/org/wrong_org_slug/courses/#{course_name}/exercises/zipexercise3/download"
        expect(page.status_code).to be(404)
      end
    end
  end

  after :all do
    FileUtils.rm_rf(repo_path)
  end
end
