require 'spec_helper'

describe CoursesController, :type => :controller do

  before(:each) do
    @user = FactoryGirl.create(:user)
  end

  describe "GET index" do
    it "shows visible courses in order by name, split into ongoing and expired" do
      controller.current_user = FactoryGirl.create(:admin)
      @courses = [
        FactoryGirl.create(:course, :name => 'SomeTestCourse'),
        FactoryGirl.create(:course, :name => 'ExpiredCourse', :hide_after => Time.now - 1.week),
        FactoryGirl.create(:course, :name => 'AnotherTestCourse')
      ]

      get :index

      expect(assigns(:ongoing_courses).map(&:name)).to eq(['AnotherTestCourse', 'SomeTestCourse'])
      expect(assigns(:expired_courses).map(&:name)).to eq(['ExpiredCourse'])
    end

    describe "in JSON format" do
      def get_index_json(options = {})
        options = {
          :format => 'json',
          :api_version => ApiVersion::API_VERSION
        }.merge options
        @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{@user.login}:#{@user.password}")
        get :index, options
        JSON.parse(response.body)
      end

      it "renders all non-hidden courses in order by name" do
        FactoryGirl.create(:course, :name => 'Course1')
        FactoryGirl.create(:course, :name => 'Course2', :hide_after => Time.now + 1.week)
        FactoryGirl.create(:course, :name => 'Course3')
        FactoryGirl.create(:course, :name => 'ExpiredCourse', :hide_after => Time.now - 1.week)
        FactoryGirl.create(:course, :name => 'HiddenCourse', :hidden => true)

        result = get_index_json

        expect(result['courses'].map {|c| c['name'] }).to eq(['Course1', 'Course2', 'Course3'])
      end
    end
  end


  describe "GET show" do
    before :each do
      @course = FactoryGirl.create(:course)
    end

    describe "for administrators" do
      before :each do
        @admin = FactoryGirl.create(:admin)
        controller.current_user = @admin
      end

      it "should show everyone's submissions" do
        user1 = FactoryGirl.create(:user)
        user2 = FactoryGirl.create(:user)
        sub1 = FactoryGirl.create(:submission, :user => user1, :course => @course)
        sub2 = FactoryGirl.create(:submission, :user => user2, :course => @course)

        get :show, :id => @course.id

        expect(assigns['submissions']).to include(sub1)
        expect(assigns['submissions']).to include(sub2)
      end
    end

    describe "for guests" do
      before :each do
        controller.current_user = Guest.new
      end

      it "should show no submissions" do
        FactoryGirl.create(:submission, :course => @course)
        FactoryGirl.create(:submission, :course => @course)

        get :show, :id => @course.id

        expect(assigns['submissions']).to be_nil
      end
    end

    describe "for regular users" do
      before :each do
        controller.current_user = @user
      end
      it "should show only the current user's submissions" do
        other_user = FactoryGirl.create(:user)
        my_sub = FactoryGirl.create(:submission, :user => @user, :course => @course)
        other_guys_sub = FactoryGirl.create(:submission, :user => other_user, :course => @course)

        get :show, :id => @course.id

        expect(assigns['submissions']).to include(my_sub)
        expect(assigns['submissions']).not_to include(other_guys_sub)
      end
    end

    describe "in JSON format" do
      before :each do
        @course = FactoryGirl.create(:course, :name => 'Course1')
        @course.exercises << FactoryGirl.create(:returnable_exercise, :name => 'Exercise1', :course => @course)
        @course.exercises << FactoryGirl.create(:returnable_exercise, :name => 'Exercise2', :course => @course)
        @course.exercises << FactoryGirl.create(:returnable_exercise, :name => 'Exercise3', :course => @course)
      end

      def get_show_json(options = {}, parse_json=true)
        options = {
          :format => 'json',
          :api_version => ApiVersion::API_VERSION,
          :id => @course.id.to_s
        }.merge options
        @request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, @user.password)
        get :show, options
        if parse_json
          JSON.parse(response.body)
        else
          response.body
        end
      end

      it "should render the exercises for each course" do
        result = get_show_json

        exs = result['course']['exercises']
        expect(exs[0]['name']).to eq('Exercise1')
        expect(exs[1]['name']).to eq('Exercise2')
        expect(exs[0]['zip_url']).to eq(exercise_url(@course.exercises[0].id, :format => 'zip'))
        expect(exs[0]['return_url']).to eq(exercise_submissions_url(@course.exercises[0].id, :format => 'json'))
      end

      it "should include only visible exercises" do
        @course.exercises[0].hidden = true
        @course.exercises[0].save!
        @course.exercises[1].deadline_spec = [Date.yesterday.to_s].to_json
        @course.exercises[1].save!

        result = get_show_json

        names = result['course']['exercises'].map { |ex| ex['name'] }
        expect(names).not_to include('Exercise1')
        expect(names).to include('Exercise2')
        expect(names).to include('Exercise3')
      end

      it "should tell each the exercise's deadline" do
        @course.exercises[0].deadline_spec = [Time.zone.parse('2011-11-16 23:59:59+0200').to_s].to_json
        @course.exercises[0].save!

        result = get_show_json

        expect(result['course']['exercises'][0]['deadline']).to eq('2011-11-16T23:59:59.000+02:00')
      end

      it "should tell for each exercise whether it has been attempted" do
        sub = FactoryGirl.create(:submission, :course => @course, :exercise => @course.exercises[0], :user => @user)
        FactoryGirl.create(:test_case_run, :submission => sub, :successful => false)

        result = get_show_json

        exs = result['course']['exercises']
        expect(exs[0]['attempted']).to be_truthy
        expect(exs[1]['attempted']).to be_falsey
      end

      it "should tell for each exercise whether it has been completed" do
        FactoryGirl.create(:submission, :course => @course, :exercise => @course.exercises[0], :user => @user, :all_tests_passed => true)

        result = get_show_json

        exs = result['course']['exercises']
        expect(exs[0]['completed']).to be_truthy
        expect(exs[1]['completed']).to be_falsey
      end

      describe "and no user given" do
        it "should respond with a 401" do
          controller.current_user = Guest.new
          get_show_json({:api_username => nil, :api_password => nil}, false)
          expect(response.code.to_i).to eq(401)
        end
      end

      describe "and the given user does not exist" do
        before :each do
          @user.destroy
        end

        it "should respond with a 401" do
          get_show_json({}, false)
          expect(response.code.to_i).to eq(401)
        end
      end
    end
  end


  describe "POST create" do

    before :each do
      controller.current_user = FactoryGirl.create(:admin)
    end

    describe "with valid parameters" do
      it "creates the course" do
        post :create, :course => { :name => 'NewCourse', :source_url => 'git@example.com' }
        expect(Course.last.source_url).to eq('git@example.com')
      end

      it "redirects to the created course" do
        post :create, :course => { :name => 'NewCourse', :source_url => 'git@example.com' }
        expect(response).to redirect_to(Course.last)
      end
    end

    describe "with invalid parameters" do
      it "re-renders the course creation form" do
        post :create, :course => { :name => 'invalid name with spaces' }
        expect(response).to render_template("new")
        expect(assigns(:course).name).to eq('invalid name with spaces')
      end
    end
  end
end


