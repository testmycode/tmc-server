require 'spec_helper'

describe SubmissionsController do
  before :each do
    @course = Factory.create(:course)
    @exercise = Factory.create(:exercise, :course => @course)
  end

  describe "POST create" do
    before :each do
      @submitted_file = mock(Object)
      @submitted_file.stub_chain(:tempfile, :path).and_return('submitted_file.zip')
      
      @submission = mock_model(Submission)
      @submission.stub(:save).and_return(true)
      Submission.stub(:new).and_return(@submission)
    end
    
    def post_create(options = {})
      options = {
        :course_id => @course.id,
        :exercise_id => @exercise.id,
        :submission => { :username => 'theuser', :file => @submitted_file }
      }.merge options
      post :create, options
    end
    
    describe "when the user doesn't exist" do
      it "should create the user and be successful" do
        post_create
        User.last.login.should == 'theuser'
      end
    end
    
    describe "when successful" do
      it "should save the submission" do
        @submission.should_receive(:save)
        post_create
      end
    
      it "should redirect to show" do
        post_create
        response.should redirect_to(submission_path(@submission))
      end
      
      it "should store the submission in the user's session" do
        post_create
        session[:recent_submissions].should_not be_nil
        session[:recent_submissions].should include(@submission.id)
      end
      
      it "should clean up the recent submissions list if it gets too long" do
        session[:recent_submissions] = [10,20,30] * 10000 + [123]
        post_create
        session[:recent_submissions].size.should == 100
        session[:recent_submissions].should include(123)
        session[:recent_submissions].should include(@submission.id)
      end
      
      describe "with json format" do
        it "should save the submission" do
          @submission.should_receive(:save)
          post_create
        end
      
        it "should redirect to show in JSON format" do
          post_create :format => :json
          response.should redirect_to(submission_path(@submission, :format => 'json'))
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
          post_create :format => :json
          JSON.parse(response.body)['error'].should_not be_blank
        end
      end
    end
    
    describe "when unsuccessful" do
      it "should redirect to exercise with failure message" do
        @submission.should_receive(:save).and_return(false)
        post_create
        response.should redirect_to(course_exercise_path(@course, @exercise))
        flash[:alert].should_not be_blank
      end
      
      describe "with json format" do
        it "should return a JSON error" do
          @submission.should_receive(:save).and_return(false)
          post_create :format => :json
          JSON.parse(response.body)['error'].should_not be_blank
        end
      end
    end
  end
  
  describe "GET show" do
    before :each do
      @user = Factory.create(:user)
      controller.current_user = @user
      
      @submission = mock_model(Submission, :user_id => @user.id)
      Submission.stub(:find).with(@submission.id.to_s).and_return(@submission)
    end
    
    it "should not allow access to guest" do
      controller.current_user = Guest.new
      
      expect { get :show, :id => @submission.id.to_s }.to raise_error(CanCan::AccessDenied)
    end
    
    it "should allow access to recent submissions" do
      controller.current_user = Guest.new
      session[:recent_submissions] = [@submission.id]
      
      get :show, :id => @submission.id.to_s
      
      response.should be_successful
      assigns[:submission].should == @submission
    end
    
    describe "in JSON format" do
      def get_show_json
        options = {
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
      
      it "should return any test failures of submissions" do
        @submission.stub(:test_failure_messages => ['one', 'two'], :status => :fail)
        result = get_show_json
        result['status'].should == 'fail'
        result['test_failures'].should == ['one', 'two']
      end
      
      it "should mark submissions with no error or failure as successful" do
        @submission.stub(:test_failure_messages => ['one', 'two'], :status => :ok)
        result = get_show_json
        result['status'].should == 'ok'
        result['error'].should be_nil
        result['test_failures'].should be_nil
      end
    end
  end
end

