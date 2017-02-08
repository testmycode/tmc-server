require 'spec_helper'

describe Api::V8::Core::CoursesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }

  before(:each) do
    controller.stub(:doorkeeper_token) { token }
  end

  describe 'GET course details show' do
    describe 'in JSON format with valid token' do
      let(:token) { double resource_owner_id: user.id, acceptable?: true }
      let(:course) { FactoryGirl.create(:course, name: 'Course1') }
      before :each do
        course.exercises << FactoryGirl.create(:returnable_exercise, name: 'Exercise1', course: course)
        course.exercises << FactoryGirl.create(:returnable_exercise, name: 'Exercise2', course: course)
        course.exercises << FactoryGirl.create(:returnable_exercise, name: 'Exercise3', course: course)
      end

      def show_course
        get :show, id: course.id
        JSON.parse(response.body)
      end

      it 'should render the exercises for each course' do
        result = show_course

        exs = result['course']['exercises']
        expect(exs[0]['name']).to eq('Exercise1')
        expect(exs[1]['name']).to eq('Exercise2')
        expect(exs[0]['zip_url']).to eq(download_api_v8_core_exercise_url(course.exercises[0].id))
        expect(exs[0]['return_url']).to eq(api_v8_core_exercise_submissions_url(course.exercises[0].id, format: 'json'))
      end

      it 'should include only visible exercises' do
        course.exercises[0].hidden = true
        course.exercises[0].save!
        course.exercises[1].deadline_spec = [Date.yesterday.to_s].to_json
        course.exercises[1].save!

        result = show_course

        names = result['course']['exercises'].map { |ex| ex['name'] }
        expect(names).not_to include('Exercise1')
        expect(names).to include('Exercise2')
        expect(names).to include('Exercise3')
      end

      it "should tell each the exercise's deadline" do
        course.exercises[0].deadline_spec = [Time.zone.parse('2011-11-16 23:59:59+0200').to_s].to_json
        course.exercises[0].save!

        result = show_course

        expect(result['course']['exercises'][0]['deadline']).to eq('2011-11-16T23:59:59.000+02:00')
      end

      it 'should tell for each exercise whether it has been attempted' do
        sub = FactoryGirl.create(:submission, course: course, exercise: course.exercises[0], user: user)
        FactoryGirl.create(:test_case_run, submission: sub, successful: false)

        result = show_course

        exs = result['course']['exercises']
        expect(exs[0]['attempted']).to be_truthy
        expect(exs[1]['attempted']).to be_falsey
      end

      it 'should tell for each exercise whether it has been completed' do
        FactoryGirl.create(:submission, course: course, exercise: course.exercises[0], user: user, all_tests_passed: true)

        result = show_course

        exs = result['course']['exercises']
        expect(exs[0]['completed']).to be_truthy
        expect(exs[1]['completed']).to be_falsey
      end

      describe 'and as guest user' do
        it 'should respond with a 403' do
          controller.current_user = Guest.new
          show_course
          expect(response.code.to_i).to eq(403)
        end
      end
    end
  end
end
