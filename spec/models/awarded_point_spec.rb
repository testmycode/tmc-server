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
    
    def make_dup_ap3_submission
      new_sub = Factory.create(:submission, :course => @course,
                                 :user => @user,
                                 :exercise => @ex1)
      Factory.create(:awarded_point, :course => @course,
                     :user => @user, :name => "ap3",
                     :submission => new_sub)
    end

    describe "#course_user_points" do
      it "should find all the user's awarded points for a given course" do
        points = AwardedPoint.course_user_points(@course, @user)
        points.size.should == 2
        points.should include("ap")
        points.should include("ap3")

        points = AwardedPoint.course_user_points(@course, @user2)
        points.size.should == 1
        points.should include("ap2")
      end
      
      it "should not return duplicates from multiple submissions" do
        make_dup_ap3_submission
        points = AwardedPoint.course_user_points(@course, @user)
        points.size.should == 2
      end
    end
    
    describe "#course_points" do
      it "should find all the user's awarded points for a given course" do
        points = AwardedPoint.course_points(@course)
        points.size.should == 3
        points.should include("ap")
        points.should include("ap2")
        points.should include("ap3")
      end
      
      it "should not return duplicates from multiple submissions" do
        make_dup_ap3_submission
        points = AwardedPoint.course_points(@course)
        points.size.should == 3
      end
    end

    describe "#course_user_sheet_points" do
      it "should find all the user's awarded points for a given gdocs sheet in a given course" do
        points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet1)
        points.size.should == 0

        points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet2)
        points.size.should == 1
        points.should include("ap2")

        points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet2)
        points.size.should == 0

        points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet1)
        points.size.should == 2
        points.should include("ap")
      end
      
      it "should not find points from another course" do
        new_point = Factory.create(:awarded_point, :name => 'new_ap', :user => @user)
        points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet1)
        points.should_not include("new_ap")
      end
      
      it "should not return duplicates from multiple submissions" do
        make_dup_ap3_submission
        points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet1)
        points.size.should == 2
      end
    end

    describe "#exercise_user_points" do
      it "should find all the user's awarded points for a given exercise in a given course" do
        p = AwardedPoint.exercise_user_points(@ex1, @user)
        p.size.should == 2
        p.should include("ap")
        p.should include("ap3")

        p = AwardedPoint.exercise_user_points(@ex2, @user)
        p.should be_empty

        p = AwardedPoint.exercise_user_points(@ex1, @user2)
        p.size.should == 0

        p = AwardedPoint.exercise_user_points(@ex2, @user2)
        p.size.should == 1
        p.should include("ap2")
      end
      
      it "should not find points from another course" do
        new_ex = Factory.create(:exercise, :name => @ex1.name) # gets a new course
        new_sub = Factory.create(:submission, :course => new_ex.course, :exercise => new_ex)
        new_point = Factory.create(:awarded_point, :submission => new_sub, :name => 'new_ap', :user => @user)
        points = AwardedPoint.exercise_user_points(@ex1, @user)
        points.should_not include("new_ap")
      end
      
      it "should not return duplicates from multiple submissions" do
        make_dup_ap3_submission
        points = AwardedPoint.exercise_user_points(@ex1, @user)
        points.size.should == 2
      end
    end
  end
end

