require 'spec_helper'

describe AwardedPoint do

  describe "scopes" do
    before :each do
      @course = Factory.create(:course)

      @user = Factory.create(:user)
      @user2 = Factory.create(:user)
      @admin = Factory.create(:admin)

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
      @sub_admin = Factory.create(:submission, :course => @course,
                                         :user => @admin,
                                         :exercise => @ex1)

      Factory.create(:available_point, :exercise => @ex1, :name => "ap")
      Factory.create(:available_point, :exercise => @ex2, :name => "ap2")
      Factory.create(:available_point, :exercise => @ex1, :name => "ap3")
      Factory.create(:available_point, :exercise => @ex1, :name => "ap_admin")

      @ap = Factory.create(:awarded_point, :course => @course,
                           :user => @user, :name => "ap",
                           :submission => @sub1)
      @ap2 = Factory.create(:awarded_point, :course => @course,
                           :user => @user2, :name => "ap2",
                           :submission => @sub2)
      @ap3 = Factory.create(:awarded_point, :course => @course,
                            :user => @user, :name => "ap3",
                            :submission => @sub1)
      @ap_admin = Factory.create(:awarded_point, :course => @course,
                                  :user => @admin, :name => "ap_admin",
                                  :submission => @sub_admin)
    end

    specify "course_points" do
      points = AwardedPoint.course_points(@course)
      points.length.should == 3
      points.should include(@ap)
      points.should include(@ap2)
      points.should include(@ap3)

      points = AwardedPoint.course_points(@course, true)
      points.length.should == 4
      points.should include(@ap)
      points.should include(@ap2)
      points.should include(@ap3)
      points.should include(@ap_admin)
    end

    specify "course_user_points" do
      p = AwardedPoint.course_user_points(@course, @user)
      p.length.should == 2
      p.should include(@ap)
      p.should include(@ap3)

      p = AwardedPoint.course_user_points(@course, @user2)
      p.length.should == 1
      p.should include(@ap2)
    end

    specify "course_sheet_points" do
      points = AwardedPoint.course_sheet_points(@course, @sheet1)
      points.length.should == 2
      points.should include(@ap)
      points.should include(@ap3)

      points = AwardedPoint.course_sheet_points(@course, @sheet1, true)
      points.length.should == 3
      points.should include(@ap)
      points.should include(@ap3)
      points.should include(@ap_admin)

      points = AwardedPoint.course_sheet_points(@course, @sheet2)
      points.length.should == 1
      points.should include(@ap2)
    end

    specify "course_user_sheet_points" do
      points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet1)
      points.length.should == 0

      points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet2)
      points.length.should == 1
      points.first.should == @ap2

      points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet2)
      points.length.should == 0

      points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet1)
      points.length.should == 2
      points.should include(@ap)
    end

    specify "count_per_user_in_course_with_sheet" do
      counts = AwardedPoint.count_per_user_in_course_with_sheet(@course, @sheet1)
      Hash[counts][@user.login].should == 2
      Hash[counts][@user2.login].should be_nil

      counts = AwardedPoint.count_per_user_in_course_with_sheet(@course, @sheet2)
      Hash[counts][@user.login].should be_nil
      Hash[counts][@user2.login].should == 1
    end

    describe "with change in exercise name" do
      before :each do
        @ex2.update_attribute(:name, 'a_different_name')
      end

      specify "course_sheet_points" do
        points = AwardedPoint.course_sheet_points(@course, @sheet2)
        points.length.should == 1
        points.should include(@ap2)
      end

      specify "course_user_sheet_points" do
        points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet2)
        points.length.should == 1
        points.first.should == @ap2
      end

      specify "count_per_user_in_course_with_sheet" do
        counts = AwardedPoint.count_per_user_in_course_with_sheet(@course, @sheet2)
        Hash[counts][@user.login].should be_nil
        Hash[counts][@user2.login].should == 1
      end
    end
  end
end

