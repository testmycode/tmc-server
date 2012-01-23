require 'spec_helper'

describe SubmissionsController do
  before :each do
    @user = Factory.create(:user)
    @course = Factory.create(:course)
    @exercise = Factory.create(:returnable_exercise, :course => @course)
    controller.current_user = @user
  end
  
  def set_upload_file_contents(contents)
    File.open('submitted_file.zip', 'wb') {|f| f.write(contents) }
    @submitted_file = fixture_file_upload('submitted_file.zip')
    class << @submitted_file
      attr_reader :tempfile # Missing for some reason. See http://comments.gmane.org/gmane.comp.lang.ruby.rails/297939
    end
  end

  describe "POST create" do
    before :each do
      set_upload_file_contents('PK') # fake zip file
      
      @submission = mock_model(Submission)
      @submission.stub(:exercise).and_return(@exercise)
      @submission.stub(:result_url).and_return('http://example.com/whatever')
      @submission.stub(:save).and_return(true)
      Submission.stub(:new).and_return(@submission)
      
      RemoteSandbox.stub(:try_to_send_submission_to_free_server)
    end
    
    def post_create(options = {})
      options = {
        :course_id => @course.id,
        :exercise_id => @exercise.id,
        :submission => { :file => @submitted_file }
      }.merge options
      post :create, options
    end
    
    describe "when successful" do
      it "should redirect to show" do
        post_create
        response.should redirect_to(submission_path(@submission))
      end
      
      it "should save the submission" do
        @submission.should_receive(:save)
        post_create
      end
      
      it "should send the submission to a remote sandbox" do
        RemoteSandbox.should_receive(:try_to_send_submission_to_free_server)
        post_create
      end
      
      describe "with json format" do
        it "should return url to submission in JSON format" do
          post_create :format => :json, :api_version => ApplicationController::API_VERSION
          JSON.parse(response.body)['submission_url'].should == submission_url(@submission, :format => 'json', :api_version => ApplicationController::API_VERSION)
        end
      end
    end
    
    describe "when exercise unavailable to current user" do
      before :each do
        @exercise.deadline = Date.yesterday
        @exercise.save
      end
      
      it "should not accept the submission" do
        @submission.should_not_receive(:save)
        post_create
        response.code.to_i.should == 403
      end
      
      describe "with json format" do
        it "should return a JSON error" do
          @submission.should_not_receive(:save)
          post_create :format => :json, :api_version => ApplicationController::API_VERSION
          JSON.parse(response.body)['error'].should_not be_blank
        end
      end
    end
    
    describe "when unable to save the submission" do
      before :each do
        @submission.should_receive(:save).and_return(false)
      end
    
      it "should redirect to exercise with failure message" do
        post_create
        response.should redirect_to(exercise_path(@exercise))
        flash[:alert].should_not be_blank
      end
      
      describe "with json format" do
        it "should return a JSON error" do
          post_create :format => :json, :api_version => ApplicationController::API_VERSION
          JSON.parse(response.body)['error'].should include('Failed to save submission')
        end
      end
    end
    
    describe "when uploaded something that doesn't look like a zip file" do
      before :each do
        set_upload_file_contents('oops what is this')
      end
      
      it "should redirect to exercise with failure message" do
        post_create
        response.should redirect_to(exercise_path(@exercise))
        flash[:alert].should_not be_blank
      end
      
      describe "with json format" do
        it "should return a JSON error" do
          post_create :format => :json, :api_version => ApplicationController::API_VERSION
          JSON.parse(response.body)['error'].should_not be_blank
        end
      end
    end
  end
  
  describe "GET show" do
    before :each do
      @user = Factory.create(:user)
      controller.current_user = @user
      
      @submission = mock_model(Submission, :user_id => @user.id, :course => @course, :exercise => @exercise)
      Submission.stub(:find).with(@submission.id.to_s).and_return(@submission)
    end
    
    it "should not allow access to guest" do
      controller.current_user = Guest.new
      
      expect { get :show, :id => @submission.id.to_s }.to raise_error(CanCan::AccessDenied)
    end
    
    describe "in JSON format" do
      def get_show_json
        options = {
          :api_version => ApplicationController::API_VERSION,
          :id => @submission.id.to_s,
          :course_id => @course.id.to_s,
          :exercise_id => @exercise.id.to_s,
          :format => 'json'
        }
        get :show, options
        JSON.parse(response.body) unless response.body.blank?
      end
      
      it "should return the error message of submissions with a pretest error" do
        @submission.stub(:pretest_error => 'oopsie happened', :status => :error)
        result = get_show_json
        result['status'].should == 'error'
        result['error'].should == 'oopsie happened'
      end
      
      it "should return any test case records returned by the model if the submission is failed" do
        records = [{'name' => 'a', 'successful' => false, 'message' => 'abc', 'exception' => "foo\nbar"}]
        @submission.stub(:test_case_records => records, :status => :fail)
        result = get_show_json
        result['status'].should == 'fail'
        result['test_cases'].should == records
      end
      
      it "should mark submissions with no error or failure as successful" do
        records = [{'name' => 'a', 'successful' => false, 'message' => 'abc'}]
        @submission.stub(:test_case_records => records, :status => :ok)
        result = get_show_json
        result['status'].should == 'ok'
        result['error'].should be_nil
        result['test_cases'].should == records
      end
    end
  end
end

