require 'spec_helper'

describe CourseRegistration do
  describe "deletion" do
    before :each do
      @course = Factory.create(:course)
      @user = Factory.create(:user)
      @reg = CourseRegistration.create!(:course => @course, :user => @user)
    end

    it "leaves the course and the user intact" do
      @reg.destroy
      Course.find_by_id(@course.id).should_not be_nil
      User.find_by_id(@user.id).should_not be_nil
    end

    it "is deleted when the course is deleted" do
      @course.delete
      CourseRegistration.all.should be_empty
      @user.courses_registered_to.reload
      @user.courses_registered_to.should be_empty
    end

    it "is deleted when the user is deleted" do
      @user.delete
      CourseRegistration.all.should be_empty
      @course.registered_users.reload
      @course.registered_users.should be_empty
    end
  end
end