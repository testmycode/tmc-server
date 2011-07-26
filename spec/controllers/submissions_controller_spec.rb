require 'spec_helper'

describe SubmissionsController do
  before :each do
    @course = mock_model(Course, :id => '1')
    Course.stub(:find).with('1').and_return(@course)
    @exercise = mock_model(Exercise, :id => '2')
    @course.stub_chain(:exercises, :find).and_return(@exercise)
  end

  describe "POST create" do
    before :each do
      @submitted_file = mock(Object)
      @submitted_file.stub_chain(:tempfile, :path).and_return('submitted_file.zip')
      
      @user = mock_model(User, :username => 'xoo')
      User.stub(:find_by_login).with('xoo').and_return(@user)
      
      @submission = mock_model(Submission, :id => '3')
      Submission.stub(:new).with(:user => @user, :exercise => @exercise, :course => @course, :return_file_tmp_path => 'submitted_file.zip').and_return(@submission)
    end
    
    def post_create(options = {})
      options = {
        :course_id => '1',
        :exercise_id => '2',
        :submission => { :username => 'xoo', :file => @submitted_file }
      }.merge options
      post :create, options
    end
    
    describe "when successful" do
      it "should redirect to show" do
        @submission.should_receive(:save).and_return(true)
        post_create
        response.should redirect_to(submission_path(@submission))
      end
      
      describe "with json format" do
        it "should redirect to show in JSON format" do
          @submission.should_receive(:save).and_return(true)
          post_create :format => :json
          response.should redirect_to(submission_path(@submission, :format => 'json'))
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
    describe "in JSON format" do
      before :each do
        @submission = mock_model(Submission)
        Submission.stub(:find).with('3').and_return(@submission)
      end
      
      def get_show_json
        options = {
          :id => '3',
          :course_id => '1',
          :exercise_id => '2',
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

