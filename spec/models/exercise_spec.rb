require 'spec_helper'

describe Exercise do
  include GitTestActions

  let(:user) { Factory.create(:user) }
  let(:course) { Factory.create(:course) }

  describe "gdocs_sheet" do
    it "should deduce gdocs_sheet from exercise name" do
      ex1 = Factory.create(:exercise, :name => "ex")
      ex1.options = {}
      ex1.gdocs_sheet.should == "root"

      ex2 = Factory.create(:exercise, :name => "wtf-ex")
      ex2.options = {}
      ex2.gdocs_sheet.should == "wtf"

      ex3 = Factory.create(:exercise, :name => "omg-wtf-ex")
      ex3.options = {}
      ex3.gdocs_sheet.should == "omg-wtf"

      ex4 = Factory.create(:exercise, :name => "omg-wtf-ex")
      ex4.options = { "points_visible" => false }
      ex4.gdocs_sheet.should == nil
    end
  end

  describe "course_gdocs_sheet_exercises scope" do
    it "should find all the exercises that belong to the gdocs_sheet" do
      sheetname = "lolwat"
      course = Factory.create(:course)
      ex1 = Factory.create(:exercise, :course => course,
                           :gdocs_sheet => sheetname)
      ex2 = Factory.create(:exercise, :course => course,
                           :gdocs_sheet => sheetname)
      ex3 = Factory.create(:exercise, :course => course,
                           :gdocs_sheet => "not#{sheetname}")
      exercises = Exercise.course_gdocs_sheet_exercises(course, sheetname)

      exercises.size.should == 2
      exercises.should include(ex1)
      exercises.should include(ex2)
      exercises.should_not include(ex3)
    end
  end


  describe "associated submissions" do
    before :each do
      @exercise = Factory.create(:exercise, :course => course, :name => 'MyExercise')
      @submission_attrs = {
        :course => course,
        :exercise_name => 'MyExercise',
        :user => user
      }
      Submission.create!(@submission_attrs)
      Submission.create!(@submission_attrs)
      @submissions = Submission.all
    end

    it "should be associated by exercise name" do
      @exercise.submissions.size.should == 2
      @submissions[0].exercise.should == @exercise
      @submissions[0].exercise_name = 'AnotherExercise'
      @submissions[0].save!
      @exercise.submissions.size.should == 1
    end
  end

  it "can be hidden with a boolean 'hidden' option" do
    ex = Factory.create(:exercise, :course => course)
    ex.options = {"hidden" => true}
    ex.should be_hidden
  end

  it "should treat date deadlines as being at 23:59:59 local time" do
    ex = Factory.create(:exercise, :course => course)
    ex.deadline = Date.today
    ex.deadline.should == Date.today.end_of_day
  end

  it "should accept deadlines in either SQLish or Finnish date format" do
    ex = Factory.create(:exercise, :course => course)

    ex.deadline = '2011-04-19 13:55'
    ex.deadline.year.should == 2011
    ex.deadline.month.should == 04
    ex.deadline.day.should == 19
    ex.deadline.hour.should == 13
    ex.deadline.min.should == 55

    ex.deadline = '25.05.2012 14:56'
    ex.deadline.day.should == 25
    ex.deadline.month.should == 5
    ex.deadline.year.should == 2012
    ex.deadline.hour.should == 14
    ex.deadline.min.should == 56
  end

  it "should accept a blank deadline" do
    ex = Factory.create(:exercise, :course => course)
    ex.deadline = nil
    ex.deadline.should be_nil
    ex.deadline = ""
    ex.deadline.should be_nil
  end

  it "should not accept certain hardcoded values for gdocs_sheet" do
    ex = Factory.create(:exercise, :course => course)
    ex.valid?.should be_true
    ex.gdocs_sheet = 'MASTER'
    ex.valid?.should be_false
    ex.gdocs_sheet = 'PUBLIC'
    ex.valid?.should be_false
    ex.gdocs_sheet = 'nonPUBLIC'
    ex.valid?.should be_true
    ex.gdocs_sheet = 'nonMASTER'
    ex.valid?.should be_true
  end

  it "should raise an exception if trying to set a deadline in invalid format" do
    ex = Factory.create(:exercise)
    expect { ex.deadline = "xooxers" }.to raise_error
    expect { ex.deadline = "2011-07-13 12:34:56:78" }.to raise_error
  end

  it "should be returnable by default if there is a non-empty test dir" do
    ex = Factory.create(:exercise, :course => course)
    FileUtils.mkdir_p('FakeCache/test')
    FileUtils.touch('FakeCache/test/Xoo.java')
    ex.stub(:clone_path => 'FakeCache')
    ex.should be_returnable
  end

  it "should be non-returnable by default if there is an empty test dir" do
    ex = Factory.create(:exercise, :course => course)
    FileUtils.mkdir_p('FakeCache/test')
    ex.stub(:clone_path => 'FakeCache')
    ex.should_not be_returnable
  end

  it "should be non-returnable by default if there is no test dir" do
    ex = Factory.create(:exercise, :course => course)
    FileUtils.mkdir_p('FakeCache')
    ex.stub(:clone_path => 'FakeCache')
    ex.should_not be_returnable
  end

  it "can be marked non-returable" do
    ex = Factory.create(:exercise, :course => course)
    ex.options = { 'returnable' => true }
    ex.should be_returnable
  end

  it "should always be submittable by administrators as long as it's returnable" do
    admin = Factory.create(:admin)
    ex = Factory.create(:returnable_exercise, :course => course)

    ex.deadline.should be_nil
    ex.should be_submittable_by(admin)

    ex.deadline = Date.today - 1.day
    ex.should be_submittable_by(admin)

    ex.hidden = true
    ex.should be_submittable_by(admin)
  end

  it "should be submittable by non-administrators only if the deadline has not passed and the exercise is not hidden and is published" do
    #TODO: publish_time too!
    user = Factory.create(:user)
    ex = Factory.create(:returnable_exercise, :course => course)

    ex.deadline.should be_nil
    ex.publish_time.should be_nil
    ex.should be_submittable_by(user)
    
    ex.publish_time = Date.today + 1.day
    ex.should_not be_submittable_by(user)
    
    ex.publish_time = Date.today - 1.day
    ex.should be_submittable_by(user)

    ex.deadline = Date.today + 1.day
    ex.should be_submittable_by(user)

    ex.deadline = Date.today - 1.day
    ex.should_not be_submittable_by(user)

    ex.deadline = nil
    ex.hidden = true
    ex.should_not be_submittable_by(user)
  end
  
  it "should never be submittable by guests" do
    ex = Factory.create(:returnable_exercise, :course => course)
    
    ex.should_not be_submittable_by(Guest.new)
  end
  
  it "should be visible to regular users by default" do
    user = Factory.create(:user)
    ex = Factory.create(:exercise, :course => course)
    
    ex.should be_visible_to(user)
  end
  
  it "should not be visible to regular users if explicitly hidden" do
    user = Factory.create(:user)
    ex = Factory.create(:exercise, :course => course, :hidden => true)
    
    ex.should_not be_visible_to(user)
  end
  
  it "should not be visible to regular users if the publish time has not passed" do
    user = Factory.create(:user)
    ex = Factory.create(:exercise, :course => course, :publish_time => Time.now + 10.hours)
    
    ex.should_not be_visible_to(user)
  end
  
  it "should always be visible to administrators unless hidden" do
    admin = Factory.create(:admin)
    ex = Factory.create(:exercise, :course => course, :publish_time => Time.now + 10.hours, :hidden => false)
    
    ex.should be_visible_to(admin)
  end
  
  it "should not be visible to administrators if hidden" do
    admin = Factory.create(:admin)
    ex = Factory.create(:exercise, :course => course, :publish_time => Time.now + 10.hours, :hidden => true)
    
    ex.should_not be_visible_to(admin)
  end

  it "can tell whether a user has ever attempted an exercise" do
    exercise = Factory.create(:exercise, :course => course)
    exercise.should_not be_attempted_by(user)

    Submission.create!(:user => user, :course => course, :exercise_name => exercise.name)
    exercise.should be_attempted_by(user)
  end

  it "can tell whether a user has completed an exercise" do
    exercise = Factory.create(:exercise, :course => course)
    exercise.should_not be_completed_by(user)

    other_user = Factory.create(:user)
    other_user_sub = Submission.create!(:user => other_user, :course => course, :exercise_name => exercise.name, :all_tests_passed => true)
    exercise.should_not be_completed_by(user)

    Submission.create!(:user => user, :course => course, :exercise_name => exercise.name, :pretest_error => 'oops', :all_tests_passed => true) # in reality all_tests_passed should always be false if pretest_error is not null
    exercise.should_not be_completed_by(user)

    sub = Submission.create!(:user => user, :course => course, :exercise_name => exercise.name, :all_tests_passed => false)
    exercise.should_not be_completed_by(user)
  end
end

