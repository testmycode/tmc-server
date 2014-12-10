require 'spec_helper'
require 'exercise_completion_status_generator'

describe ExerciseCompletionStatusGenerator, "completion status" do
  before do
    @user = FactoryGirl.create(:user)
    @course = FactoryGirl.create(:course)
    @ex1 = exercise("ex1", ["1.1", "1.2"])
    @ex2 = exercise("ex2", ["2"])
    @ex3 = exercise("ex3", ["3.1", "3.2", "3.3", "3.4"])
  end

  it "is generated for each of the exercises" do
    completion_status = ExerciseCompletionStatusGenerator.completion_status @user, @course
    expect(completion_status.keys.sort).to eq([@ex1.id, @ex2.id, @ex3.id])
  end

  it "is empty for each exercise without submissions and awarded points" do
    completion_status = ExerciseCompletionStatusGenerator.completion_status @user, @course
    completion_status.keys.each { |exercise|
      expect(completion_status[exercise]).to eq(nil)
    }
  end

  describe "with awarded points and no submissions" do
    it "is correctly generated in case 1" do
      award_points ["2", "3.1", "3.2", "3.3"]
      completion_status = ExerciseCompletionStatusGenerator.completion_status @user, @course

      expect(completion_status[@ex1.id]).to eq(nil)
      expect(completion_status[@ex2.id]).to eq(100)
      expect(completion_status[@ex3.id]).to eq(75)
    end

    it "is correctly generated in case 2" do
      award_points ["1.1", "1.2", "3.1"]
      completion_status = ExerciseCompletionStatusGenerator.completion_status @user, @course

      expect(completion_status[@ex1.id]).to eq(100)
      expect(completion_status[@ex2.id]).to eq(nil)
      expect(completion_status[@ex3.id]).to eq(25)
    end
  end

  describe "with only unsuccesful submissions and no awarded points" do
    it "is set to 0%" do
      submission(@ex1)
      submission(@ex2)
      completion_status = ExerciseCompletionStatusGenerator.completion_status @user, @course

      expect(completion_status[@ex1.id]).to eq(0)
      expect(completion_status[@ex2.id]).to eq(0)
      expect(completion_status[@ex3.id]).to eq(nil)
    end
  end

  describe "with succesful submissions" do
    it "is correctly generated (i.e. submissions have no effect)" do
      submission(@ex1, "1")
      submission(@ex2, "2")
      submission(@ex3, "3.2")

      award_points ["2", "3.1", "3.3"]
      completion_status = ExerciseCompletionStatusGenerator.completion_status @user, @course
      expect(completion_status[@ex1.id]).to eq(0)
      expect(completion_status[@ex2.id]).to eq(100)
      expect(completion_status[@ex3.id]).to eq(50)
    end
  end

  def submission(exercise, points = '')
    FactoryGirl.create(:submission, course_id: @course.id, exercise_name: exercise.name, user_id: @user.id, points: points)
  end

  def exercise(name, points)
    FactoryGirl.create(:exercise, course_id: @course.id, name: name, available_points: point_objects(points))
  end

  def point_objects(point_names)
    point_names.map {|name| AvailablePoint.new(name: name) }
  end

  def award_points(names)
    names.map {|name| AwardedPoint.create(name: name, course_id: @course.id, user_id: @user.id) }
  end
end
