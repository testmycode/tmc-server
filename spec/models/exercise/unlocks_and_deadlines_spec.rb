require 'spec_helper'

describe Exercise, type: :model do
  describe "unlocks and deadlines" do
    before :each do
      @user = FactoryGirl.create(:user)
      @course = FactoryGirl.create(:course)
      @ex1 = FactoryGirl.create(:exercise, course: @course, name: 'ex1')
      @ex2 = FactoryGirl.create(:exercise, course: @course, name: 'ex2')
      @points = [
        AvailablePoint.create!(exercise_id: @ex1.id, name: 'ap1'),
        AvailablePoint.create!(exercise_id: @ex1.id, name: 'ap2')
      ]
    end

    specify "unlock after another exercise is 30% complete" do
      @ex2.options = { 'unlocked_after' => "30% of ex1" }
      @ex2.save!
      invalidate_unlocks
      expect(@ex2).not_to be_unlocked_for(@user)

      @points[0].award_to(@user)
      @course.reload
      invalidate_unlocks
      expect(@ex2).to be_unlocked_for(@user)
    end

    specify "unlock after another exercise is 70% complete" do
      @ex2.options = { 'unlocked_after' => "70% of ex1" }
      @ex2.save!
      expect(@ex2.requires_explicit_unlock?).to eq(false)
      invalidate_unlocks
      expect(@ex2).not_to be_unlocked_for(@user)

      @points[0].award_to(@user)
      invalidate_unlocks
      expect(@ex2).not_to be_unlocked_for(@user)

      @points[1].award_to(@user)
      invalidate_unlocks
      expect(@ex2).to be_unlocked_for(@user)
    end

    specify "deadline depending on unlock" do
      @ex2.options = { 'unlocked_after' => "exercise ex1", 'deadline' => "unlock + 5 days" }
      @ex2.save!
      @points.each {|pt| pt.award_to(@user) }
      invalidate_unlocks

      @ex2.reload
      expect(@ex2.requires_explicit_unlock?).to eq(true)
      expect(@ex2).not_to be_unlocked_for(@user)
      expect(@ex2.deadline_for(@user)).to be_nil

      Unlock.unlock_exercises([@ex2], @user)
      @ex2.reload
      expect(@ex2).to be_unlocked_for(@user)
      expect(@ex2.deadline_for(@user)).to be_within(5.minutes).of(Time.now + 5.days)
    end

    def invalidate_unlocks
      @course.reload
      UncomputedUnlock.create_all_for_course(@course)
    end
  end
end