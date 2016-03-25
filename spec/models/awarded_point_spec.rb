require 'spec_helper'

describe AwardedPoint, type: :model do
  describe 'scopes' do
    before :each do
      @course = FactoryGirl.create(:course)

      @user = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user)
      @admin = FactoryGirl.create(:admin)

      @sheet1 = 'sheet1'
      @sheet2 = 'sheet2'

      @ex1 = FactoryGirl.create(:exercise, course: @course,
                                           gdocs_sheet: @sheet1)
      @ex2 = FactoryGirl.create(:exercise, course: @course,
                                           gdocs_sheet: @sheet2)

      @sub1 = FactoryGirl.create(:submission, course: @course,
                                              user: @user,
                                              exercise: @ex1)
      @sub2 = FactoryGirl.create(:submission, course: @course,
                                              user: @user2,
                                              exercise: @ex2)
      @sub_admin = FactoryGirl.create(:submission, course: @course,
                                                   user: @admin,
                                                   exercise: @ex1)

      FactoryGirl.create(:available_point, exercise: @ex1, name: 'ap')
      FactoryGirl.create(:available_point, exercise: @ex2, name: 'ap2')
      FactoryGirl.create(:available_point, exercise: @ex1, name: 'ap3')
      FactoryGirl.create(:available_point, exercise: @ex1, name: 'ap_admin')

      @ap = FactoryGirl.create(:awarded_point, course: @course,
                                               user: @user, name: 'ap',
                                               submission: @sub1)
      @ap2 = FactoryGirl.create(:awarded_point, course: @course,
                                                user: @user2, name: 'ap2',
                                                submission: @sub2)
      @ap3 = FactoryGirl.create(:awarded_point, course: @course,
                                                user: @user, name: 'ap3',
                                                submission: @sub1)
      @ap_admin = FactoryGirl.create(:awarded_point, course: @course,
                                                     user: @admin, name: 'ap_admin',
                                                     submission: @sub_admin)
    end

    specify 'course_points' do
      points = AwardedPoint.course_points(@course)
      expect(points).to eq(3)

      points = AwardedPoint.course_points(@course, true)
      expect(points).to eq(4)
    end

    specify 'course_user_points' do
      p = AwardedPoint.course_user_points(@course, @user)
      expect(p.length).to eq(2)
      expect(p).to include(@ap)
      expect(p).to include(@ap3)

      p = AwardedPoint.course_user_points(@course, @user2)
      expect(p.length).to eq(1)
      expect(p).to include(@ap2)
    end

    specify 'course_sheet_points' do
      points = AwardedPoint.course_sheet_points(@course, @sheet1)
      expect(points[@sheet1]).to eq(2)

      points = AwardedPoint.course_sheet_points(@course, @sheet1, true)
      expect(points[@sheet1]).to eq(3)

      points = AwardedPoint.course_sheet_points(@course, @sheet2)
      expect(points[@sheet2]).to eq(1)
    end

    specify 'course_user_sheet_points' do
      points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet1)
      expect(points.length).to eq(0)

      points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet2)
      expect(points.length).to eq(1)
      expect(points.first).to eq(@ap2)

      points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet2)
      expect(points.length).to eq(0)

      points = AwardedPoint.course_user_sheet_points(@course, @user, @sheet1)
      expect(points.length).to eq(2)
      expect(points).to include(@ap)
    end

    specify 'count_per_user_in_course_with_sheet' do
      counts = AwardedPoint.count_per_user_in_course_with_sheet(@course, @sheet1)
      expect(counts[@user.login][@sheet1]).to eq(2)
      expect(counts[@user2.login]).to be_nil

      counts = AwardedPoint.count_per_user_in_course_with_sheet(@course, @sheet2)
      expect(counts[@user.login]).to be_nil
      expect(counts[@user2.login][@sheet2]).to eq(1)
    end

    describe 'with change in exercise name' do
      before :each do
        @ex2.update_attribute(:name, 'a_different_name')
      end

      specify 'course_sheet_points' do
        points = AwardedPoint.course_sheet_points(@course, @sheet2)
        expect(points[@sheet2]).to eq(1)
      end

      specify 'course_user_sheet_points' do
        points = AwardedPoint.course_user_sheet_points(@course, @user2, @sheet2)
        expect(points.length).to eq(1)
        expect(points.first).to eq(@ap2)
      end

      specify 'count_per_user_in_course_with_sheet' do
        points = AwardedPoint.count_per_user_in_course_with_sheet(@course, @sheet2)
        expect(points[@user2.login][@sheet2]).to eq(1)
      end
    end
  end
end
