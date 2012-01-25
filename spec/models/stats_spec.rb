require 'spec_helper'

describe Stats do
  it "should give interesting statistics about the system" do
    course1 = Factory.create(:course, :name => 'course1')
    course2 = Factory.create(:course, :name => 'course2')
    cat1ex1 = Factory.create(:exercise, :course => course1, :name => 'cat1-ex1')
    cat1ex2 = Factory.create(:exercise, :course => course1, :name => 'cat1-ex2')
    cat2ex1 = Factory.create(:exercise, :course => course1, :name => 'cat2-ex1')
    cat3ex1 = Factory.create(:exercise, :course => course2, :name => 'cat3-ex1')
    hiddenex = Factory.create(:exercise, :course => course1, :name => 'cat1-hiddenex', :hidden => true)
    
    user1 = Factory.create(:user)
    user2 = Factory.create(:user)
    user3 = Factory.create(:user)
    create_successful_submission(:course => course1, :exercise => cat1ex1, :user => user1)
    create_successful_submission(:course => course1, :exercise => cat1ex1, :user => user2)
    create_successful_submission(:course => course1, :exercise => cat1ex2, :user => user1)
    create_successful_submission(:course => course1, :exercise => cat2ex1, :user => user1)
    create_successful_submission(:course => course2, :exercise => cat3ex1, :user => user1)
    
    stats = Stats.all
    
    stats[:registered_users].should == 3
    
    cs = stats[:course_stats]
    cs['course1'][:participants_with_submissions_count].should == 2
    cs['course1'][:completed_exercise_count].should == 4
    cs['course1'][:possible_completed_exercise_count].should == 6 # 2 users with subs and 3 exercises
    cs['course2'][:participants_with_submissions_count].should == 1
    cs['course2'][:completed_exercise_count].should == 1
    cs['course2'][:possible_completed_exercise_count].should == 1 # 1 user with subs and 1 exercise
    
    egs = cs['course1'][:exercise_group_stats]
    egs['cat1'][:participants_with_submissions_count].should == 2
    egs['cat1'][:completed_exercise_count].should == 3
    egs['cat1'][:possible_completed_exercise_count].should == 4
    egs['cat2'][:participants_with_submissions_count].should == 1
    egs['cat2'][:completed_exercise_count].should == 1
    egs['cat2'][:possible_completed_exercise_count].should == 1
  end
  
  def create_successful_submission(opts)
    sub = Factory.create(:submission, opts.merge(:all_tests_passed => true))
    Factory.create(:test_case_run, :submission => sub, :successful => true)
    sub.status.should == :ok
    sub
  end
end

