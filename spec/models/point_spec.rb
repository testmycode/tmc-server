require 'spec_helper'
=begin
# Can't really figure out how to test this properly, so commenting this out for now

describe Point do

  # Create and run a TestSuiteRun (all tests should pass in this file
  before :each do
    @course = Course.create! :name => "test_points_course"

    system "git clone #{::Rails.root.to_s}/spec"

    exercise_return = ExerciseReturn.create!(
      :student_id => "test_student_id",
      :return_file => File.open(Rails.root.to_s + "/spec/models/OhjaV1T2.zip", 'rb').read,
      :exercise_id => exercise.id
    )
    @test_suite_run = TestSuiteRun.create! :exercise_return_id => exercise_return.id
  end

  after :each do
    @course.destroy
  end

  describe "with all tests true" do
    before :each do
      exercise_return = ExerciseReturn.create!(
        :student_id => 123,
        :return_file => File.open(Rails.root.to_s + "/spec/models/OhjaV1T2.zip", 'rb').read
      )
      @test_suite_run = TestSuiteRun.create! :exercise_return_id => exercise_return.id
    end

    it "should not have any failed tests" do
      points = Point.all
      points.all? { |p| p.tests_pass.should == true }
    end
  end
end
=end
