require 'spec_helper'

describe AwardedPoint do

  describe "scopes" do
    before :each do
      @course = Factory.create(:course)

      @user = Factory.create(:user)
      @user2 = Factory.create(:user)

      @sheet1 = "sheet1"
      @sheet2 = "sheet2"

      @ex1 = Factory.create(:exercise, :course => @course,
                                 :gdocs_sheet => @sheet1)
      @ex2 = Factory.create(:exercise, :course => @course,
                                 :gdocs_sheet => @sheet2)

      @sub1 = Factory.create(:submission, :course => @course,
                                   :user => @user,
                                   :exercise => @ex1)
      @sub2 = Factory.create(:submission, :course => @course,
                                   :user => @user2,
                                   :exercise => @ex2)

      @ap = Factory.create(:awarded_point, :course => @course,
                           :user => @user, :name => "ap",
                           :submission => @sub1)
      @ap2 = Factory.create(:awarded_point, :course => @course,
                           :user => @user2, :name => "ap2",
                           :submission => @sub2)
      @ap3 = Factory.create(:awarded_point, :course => @course,
                            :user => @user, :name => "ap3",
                            :submission => @sub1)
    end

    it "course_user_points" do
      p = AwardedPoint.course_user_points(@course, @user)
      p.length.should == 2
      p.should include(@ap)
      p.should include(@ap3)

      p = AwardedPoint.course_user_points(@course, @user2)
      p.length.should == 1
      p.should include(@ap2)
    end

    it "course_user_sheet_points" do
      points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet1)
      points.length.should == 0

      points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet2)
      points.length.should == 1
      points.first.should == @ap2

      points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet2)
      points.length.should == 0

      points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet1)
      points.length.should == 2
      points.first.should == @ap
    end

    it "exercise_user_points" do
      p = AwardedPoint.exercise_user_points(@ex1, @user)
      p.length.should == 2
      p.should include(@ap)
      p.should include(@ap3)

      p = AwardedPoint.exercise_user_points(@ex2, @user)
      p.should be_empty

      p = AwardedPoint.exercise_user_points(@ex1, @user2)
      p.length.should == 0

      p = AwardedPoint.exercise_user_points(@ex2, @user2)
      p.length.should == 1
      p.should include(@ap2)
    end
  end
end

