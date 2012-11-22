require 'spec_helper'

describe Exercise do
  describe "unlocks and deadlines" do
    before :each do
      @user = Factory.create(:user)
      @course = Factory.create(:course)
      @ex1 = Factory.create(:exercise, :course => @course, :name => 'ex1')
      @ex2 = Factory.create(:exercise, :course => @course, :name => 'ex2')
      @points = [
        AvailablePoint.create!(:exercise_id => @ex1.id, :name => 'ap1'),
        AvailablePoint.create!(:exercise_id => @ex1.id, :name => 'ap2')
      ]
    end

    specify "unlock after another exercise is 30% complete" do
      @ex2.options = { 'unlocked_after' => "30% of ex1" }
      @ex2.save!
      refresh_unlocks
      @ex2.should_not be_unlocked_for(@user)

      @points[0].award_to(@user)
      @course.reload
      refresh_unlocks
      @ex2.should be_unlocked_for(@user)
    end

    specify "unlock after another exercise is 70% complete" do
      @ex2.options = { 'unlocked_after' => "70% of ex1" }
      @ex2.save!
      @ex2.requires_explicit_unlock?.should == false
      refresh_unlocks
      @ex2.should_not be_unlocked_for(@user)

      @points[0].award_to(@user)
      refresh_unlocks
      @ex2.should_not be_unlocked_for(@user)

      @points[1].award_to(@user)
      refresh_unlocks
      @ex2.should be_unlocked_for(@user)
    end

    specify "deadline depending on unlock" do
      @ex2.options = { 'unlocked_after' => "exercise ex1", 'deadline' => "unlock + 5 days" }
      @ex2.save!
      @points.each {|pt| pt.award_to(@user) }
      refresh_unlocks

      @ex2.reload
      @ex2.requires_explicit_unlock?.should == true
      @ex2.should_not be_unlocked_for(@user)
      @ex2.deadline_for(@user).should be_nil

      Unlock.unlock_exercises([@ex2], @user)
      @ex2.reload
      @ex2.should be_unlocked_for(@user)
      @ex2.deadline_for(@user).should be_within(5.minutes).of(Time.now + 5.days)
    end

    def refresh_unlocks
      @course.reload
      Unlock.refresh_all_unlocks(@course)
    end
  end
end