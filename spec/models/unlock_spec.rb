require 'spec_helper'

describe Unlock do
  describe "#refresh_unlocks" do
    before :each do
      @course = Factory.create(:course)
      @ex1 = Factory.create(:exercise, :course => @course, :name => 'ex1')
      @ex2 = Factory.create(:exercise, :course => @course, :name => 'ex2')
      @ex1.unlock_spec = ['11.11.2011'].to_json
      @ex2.unlock_spec = ['2011-11-22', 'exercise ex1'].to_json
      @ex1.save!
      @ex2.save!

      @user = Factory.create(:user)
      @available_point = Factory.create(:available_point, :exercise_id => @ex1.id)
    end

    it "creates unlocks as specified" do
      Unlock.refresh_unlocks(@course, @user)
      unlocks = Unlock.order('exercise_name ASC').to_a
      unlocks.size.should == 1

      unlocks.first.valid_after.should == Date.parse('2011-11-11').to_time_in_current_zone
      unlocks.first.exercise_name.should == 'ex1'

      AwardedPoint.create!(:user_id => @user.id, :course_id => @course.id, :name => @available_point.name)
      Unlock.refresh_unlocks(@course, @user)

      unlocks = Unlock.order('exercise_name ASC').to_a
      unlocks.size.should == 2

      unlocks.second.valid_after.should == Date.parse('2011-11-22').to_time_in_current_zone
      unlocks.second.exercise_name.should == 'ex2'
    end

    it "doesn't recreate old unlocks" do
      Unlock.refresh_unlocks(@course, @user)
      u = Unlock.where(:exercise_name => 'ex1').first
      id, created_at = [u.id, u.created_at]

      Unlock.refresh_unlocks(@course, @user)
      u = Unlock.where(:exercise_name => 'ex1').first
      u.id.should == id
      u.created_at.should == created_at
    end

    it "deletes unlocks whose conditions changed" do
      Unlock.refresh_unlocks(@course, @user)
      @ex1.unlock_spec = ['exercise ex2'].to_json
      @ex1.save!
      @course.reload
      Unlock.refresh_unlocks(@course, @user)
      Unlock.where(:exercise_name => 'ex1').should be_empty
    end

    it "updates unlocks whose unlock time changes" do
      Unlock.refresh_unlocks(@course,@user)

      @ex1.unlock_spec = [(Date.today + 3.days).to_s].to_json
      @ex1.save!
      @course.reload
      Unlock.refresh_unlocks(@course, @user)
      u = Unlock.where(:exercise_name => 'ex1').first
      u.valid_after.should > Date.today + 2.days

      @ex1.unlock_spec = [].to_json
      @ex1.save!
      @course.reload
      Unlock.refresh_unlocks(@course, @user)
      u = Unlock.where(:exercise_name => 'ex1').first
      u.valid_after.should be_nil
    end

  end
end