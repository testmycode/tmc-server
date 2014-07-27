require 'spec_helper'

describe "Paste JSON api" , :integration => true do
  include IntegrationTestActions

  before :each do
    repo_path = Dir.pwd + '/remote_repo'
    create_bare_repo(repo_path)
    @course = Course.create!(:name => 'mycourse', :source_backend => 'git', :source_url => repo_path)
    @repo = clone_course_repo(@course)
    @repo.copy_simple_exercise('MyExercise')
    @repo.add_commit_push

    @course.refresh

    @admin = Factory.create(:admin, :password => 'xooxer')
    @user = Factory.create(:user, :login => 'user',  :password => 'xooxer')
    @viewer = Factory.create(:user, :login => 'viewer', :password => 'xooxer')

  end

  def get_paste(id, user)
    get "/paste/#{id}.json", {api_version: ApiVersion::API_VERSION}, { "Accept" => "application/json", 'HTTP_AUTHORIZATION' =>  basic_auth(user) }
  end



  def basic_auth(user)
    ActionController::HttpAuthentication::Basic.encode_credentials(user.login, 'xooxer')
  end

  def create_paste_submission(solve = false, user = nil, time = Time.now)
    visit '/'
    log_in_as(user.login, 'xooxer')
    click_link 'mycourse'
    ex = FixtureExercise::SimpleExercise.new('MyExercise')
    ex.solve_all if solve
    ex.make_zip

    click_link 'MyExercise'
    attach_file('Zipped project', 'MyExercise.zip')
    check('Submit to pastebin')
    click_button 'Submit'
    wait_for_submission_to_be_processed
    submission = Submission.last
    submission.created_at = time
    submission.save!
    submission
  end

  describe "right after submission" do
    describe "for admins" do
      it "it should show test results for " do
        submission = create_paste_submission(false, @admin)
        get_paste(submission.paste_key, @admin)
        response.should be_success
        json = JSON.parse(response.body)
        json.should have_key("api_version")
        json.should have_key("test_cases")
        json.should have_key("message_for_paste")
        json.should have_key("all_tests_passed")
      end
    end

    describe "for non admins and not the author" do
      it "it should give access_denied if all_tests_passed" do
        submission = create_paste_submission(true, @user)
        get_paste(submission.paste_key, @viewer)
        response.should_not be_success
        response.should be_forbidden
        json = JSON.parse(response.body)
        json.should_not have_key("api_version")
        json.should_not have_key("test_cases")
        json.should_not have_key("message_for_paste")
        json.should_not have_key("all_tests_passed")
        json.should_not have_key("processing_time")
      end
      it "it should give show results if all tests didn't pass" do
        submission = create_paste_submission(false, @user)
        get_paste(submission.paste_key, @viewer)
        response.should be_success
        response.should_not be_forbidden
        json = JSON.parse(response.body)
        json.should have_key("api_version")
        json.should have_key("test_cases")
        json.should have_key("message_for_paste")
        json.should have_key("all_tests_passed")
      end
    end

    describe "for the author" do
      it "it should return results if all_tests_passed" do
        submission = create_paste_submission(true, @user)
        get_paste(submission.paste_key, @user)
        response.should be_success
        json = JSON.parse(response.body)
        json.should have_key("api_version")
        json.should have_key("exercise_name")
        json.should have_key("test_cases")
        json.should have_key("message_for_paste")
        json.should have_key("all_tests_passed")
        json.should have_key("processing_time")
      end
    end
  end

  describe "after one day" do
    describe "for admins" do
      it "it should show test results" do
        submission = create_paste_submission(true, @admin, 1.day.ago)
        get_paste(submission.paste_key, @admin)
        response.should be_success
        json = JSON.parse(response.body)
        json.should have_key("api_version")
        json.should have_key("exercise_name")
        json.should have_key("test_cases")
        json.should have_key("message_for_paste")
        json.should have_key("all_tests_passed")
        json.should have_key("processing_time")
      end
    end

    describe "for non admins and not the author" do
      it "it should give access_denied when visiting old paste link" do
        submission = create_paste_submission(false, @user, 1.day.ago)
        get_paste(submission.paste_key, @viewer)
        response.should_not be_success
        response.should be_forbidden
        json = JSON.parse(response.body)
        json.should_not have_key("api_version")
        json.should_not have_key("exercise_name")
        json.should_not have_key("test_cases")
        json.should_not have_key("message_for_paste")
        json.should_not have_key("all_tests_passed")
        json.should_not have_key("processing_time")
      end
    end

    describe "for the author" do
      it "it should return results when visiting an old paste" do
        submission = create_paste_submission(false, @user, 1.day.ago)
        get_paste(submission.paste_key, @user)
        response.should be_success
        json = JSON.parse(response.body)
        json.should have_key("api_version")
        json.should have_key("exercise_name")
        json.should have_key("test_cases")
        json.should have_key("message_for_paste")
        json.should have_key("all_tests_passed")
      end
    end
  end
end
