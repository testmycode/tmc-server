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
                           :user => @user, :submission => @sub1,
                           :name => "ap")
      @ap2 = Factory.create(:awarded_point, :course => @course,
                           :user => @user2, :name => "ap2",
                           :submission => @sub2)
      @ap3 = Factory.create(:awarded_point, :course => @course,
                            :user => @user2, :name => "ap3",
                            :submission => @sub1)
    end

    it "course_user_points" do
      points = AwardedPoint.course_user_points(@course, @user)
      points.size.should == 1
      points.first.should == @ap

      points2 = AwardedPoint.course_user_points(@course, @user2)
      points2.size.should == 2
      points2.should include(@ap2)
      points2.should include(@ap3)
    end

    it "course_user_sheet_points" do
      points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet1)
      points.size.should == 1
      points.first.should == @ap3

      points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet2)
      points.size.should == 1
      points.first.should == @ap2

      points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet2)
      points.size.should == 0

      points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet1)
      points.size.should == 1
      points.first.should == @ap
    end

  end

end

