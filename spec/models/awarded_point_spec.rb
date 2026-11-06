# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe AwardedPoint, type: :model do
  describe 'scopes' do
    before :each do
      @course = FactoryBot.create(:course)

      @user = FactoryBot.create(:user)
      @user2 = FactoryBot.create(:user)
      @admin = FactoryBot.create(:admin)

      @sheet1 = 'sheet1'
      @sheet2 = 'sheet2'

      @ex1 = FactoryBot.create(:exercise, course: @course,
                                           gdocs_sheet: @sheet1)
      @ex2 = FactoryBot.create(:exercise, course: @course,
                                           gdocs_sheet: @sheet2)

      @sub1 = FactoryBot.create(:submission, course: @course,
                                              user: @user,
                                              exercise: @ex1)
      @sub2 = FactoryBot.create(:submission, course: @course,
                                              user: @user2,
                                              exercise: @ex2)
      @sub_admin = FactoryBot.create(:submission, course: @course,
                                                   user: @admin,
                                                   exercise: @ex1)

      FactoryBot.create(:available_point, exercise: @ex1, name: 'ap')
      FactoryBot.create(:available_point, exercise: @ex2, name: 'ap2')
      FactoryBot.create(:available_point, exercise: @ex1, name: 'ap3')
      FactoryBot.create(:available_point, exercise: @ex1, name: 'ap_admin')

      @ap = FactoryBot.create(:awarded_point, course: @course,
                                               user: @user, name: 'ap',
                                               submission: @sub1)
      @ap2 = FactoryBot.create(:awarded_point, course: @course,
                                                user: @user2, name: 'ap2',
                                                submission: @sub2)
      @ap3 = FactoryBot.create(:awarded_point, course: @course,
                                                user: @user, name: 'ap3',
                                                submission: @sub1)
      @ap_admin = FactoryBot.create(:awarded_point, course: @course,
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

    specify 'users_in_course_with_sheet excludes points of exercises with hidden results' do
      expect(AwardedPoint.users_in_course_with_sheet(@course, @sheet2)).to eq([@user2])

      @ex2.update!(hide_submission_results: true)
      expect(AwardedPoint.users_in_course_with_sheet(@course, @sheet2)).to eq([])
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

  describe 'when its submission has been deleted' do
    let(:course) { FactoryBot.create(:course, moocfi_id: SecureRandom.hex(16)) }
    let(:point) do
      submission = FactoryBot.create(:submission, course: course)
      point = FactoryBot.create(:awarded_point, course: course, user: submission.user, submission: submission)
      submission.destroy
      KafkaBatchUpdatePoints.delete_all
      AwardedPoint.find(point.id)
    end

    it 'is listed without an exercise id' do
      json = AwardedPoint.as_json_with_exercise_ids([point], course.exercises)
      expect(json).to eq([{ awarded_point: point.point_as_json, exercise_id: nil }])
    end

    it 'saves and destroys without queueing progress updates' do
      point.update!(name: 'renamed')
      point.destroy!
      expect(KafkaBatchUpdatePoints.count).to eq(0)
    end
  end
end
