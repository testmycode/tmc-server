require 'spec_helper'

describe UncomputedUnlock do
  describe "#create_all_for_course" do
    before :each do
      @course = Factory.create(:course)
      @user = Factory.create(:user)

      # make the user a course participant
      Factory.create(:awarded_point, :course => @course, :user => @user)
      User.course_students(@course).should include(@user)

      # Create irrelevant course and user
      Factory.create(:course)
      Factory.create(:user)
    end

    it "creates entries for all students of a course" do
      UncomputedUnlock.create_all_for_course(@course)
      UncomputedUnlock.count.should be (1)
      UncomputedUnlock.first.course_id.should be (@course.id)
      UncomputedUnlock.first.user_id.should be (@user.id)
    end

    it "tries to not create duplicate entries" do
      UncomputedUnlock.create_all_for_course(@course)
      UncomputedUnlock.create_all_for_course(@course)
      UncomputedUnlock.count.should be (1)
    end
  end
end
