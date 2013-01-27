require 'spec_helper'
require 'gdocs_export'
require 'exercise_status_generator'

describe ExerciseStatusGenerator, "completion status" do
  before do
    ex1 = exercise(1, "ex1", ["1.1", "1.2"])
    ex2 = exercise(2, "ex2", ["2"])
    ex3 = exercise(3, "ex3", ["3.1", "3.2", "3.3"])
    Exercise.stub(:find_all_by_course_id).and_return([ex1, ex2, ex3])

    Exercise.stub(:find_by_course_id_and_name).with(1, "ex1").and_return(ex1)
    Exercise.stub(:find_by_course_id_and_name).with(1, "ex2").and_return(ex2)
    Exercise.stub(:find_by_course_id_and_name).with(1, "ex3").and_return(ex3)
  end

  it "is generated for each of the exercises" do
    completion_status = ExerciseStatusGenerator.completion_status_with [], [], 1
    completion_status.keys.sort.should == [1,2,3]
  end

  it "is empty for each exercise without submissions and awarded points" do
    completion_status = ExerciseStatusGenerator.completion_status_with [], [], 1
    completion_status.keys.each { |exercise|
      completion_status[exercise].should  == ""
    }
  end

  describe "with awarded points and no submissions" do
    it "is correctly generated in case 1" do
      points = ["2", "3.1", "3.3"]
      completion_status = ExerciseStatusGenerator.completion_status_with points, [], 1
      completion_status[1].should  == ""
      completion_status[2].should  == "exercise p100"
      completion_status[3].should  == "exercise p60"
    end

    it "is correctly generated in case 2" do
      points = ["1.1", "1.2", "3.1"]
      completion_status = ExerciseStatusGenerator.completion_status_with points, [], 1
      completion_status[1].should  == "exercise p100"
      completion_status[2].should  == ""
      completion_status[3].should  == "exercise p30"
    end
  end

  describe "with unsuccesful submissions" do
    it "is set 0% without awarded points" do
      submissions = [submission("ex1"), submission("ex2")]

      completion_status = ExerciseStatusGenerator.completion_status_with [], submissions, 1
      completion_status[1].should  == "exercise p0"
      completion_status[2].should  == "exercise p0"
      completion_status[3].should  == ""
    end
  end

  describe "with succesful submission" do
    it "is correctly generated (i.e. submissions have no effect)" do
      submissions = [submission("ex1", "1"), submission("ex2", "2"), submission("ex3", "3.2")]

      points = ["2", "3.1", "3.3"]
      completion_status = ExerciseStatusGenerator.completion_status_with points, submissions, 1
      completion_status[1].should  == ""
      completion_status[2].should  == "exercise p100"
      completion_status[3].should  == "exercise p60"
    end
  end

end

# stub builders

def submission exercise, points=nil
  Submission.new(:exercise_name => exercise,:points => points)
end

def exercise id, name, points
  ex = Exercise.new( :name => name, :available_points => points(points) )
  ex.id = id
  ex
end

def points names
  names.inject([]) { |points, name|
    points << AvailablePoint.new(:name => name)
  }
end