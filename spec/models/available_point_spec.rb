# frozen_string_literal: true

require 'spec_helper'

describe AvailablePoint, type: :model do
  describe 'sorting' do
    it 'should use natural sorting' do
      a = [FactoryBot.create(:available_point, name: '1.2'),
           FactoryBot.create(:available_point, name: '1.20'),
           FactoryBot.create(:available_point, name: '1.3')].sort!

      expect(a.first.name).to eq('1.2')
      expect(a.last.name).to eq('1.20')
    end
  end

  describe 'scopes' do
    specify 'course_sheet_points' do
      course = FactoryBot.create(:course)
      ex1 = FactoryBot.create(:exercise, course: course, gdocs_sheet: 's1')
      ex2 = FactoryBot.create(:exercise, course: course, gdocs_sheet: 's2')

      ap1 = FactoryBot.create(:available_point, exercise: ex1)
      ap2 = FactoryBot.create(:available_point, exercise: ex2)

      a = AvailablePoint.course_sheet_points(course, 's1')
      expect(a.size).to eq(1)
      expect(a['s1']).to eq(1)

      a = AvailablePoint.course_sheet_points(course, 's2')
      expect(a.size).to eq(1)
      expect(a['s2']).to eq(1)

      a = AvailablePoint.course_sheet_points(course, %w[s1 s2])
      expect(a.size).to eq(2)
      expect(a['s1']).to eq(1)
      expect(a['s2']).to eq(1)
    end

    specify 'course_points_of_exercises' do
      course = FactoryBot.create(:course)
      ex1 = FactoryBot.create(:exercise, course: course, gdocs_sheet: 's1')
      ex2 = FactoryBot.create(:exercise, course: course, gdocs_sheet: 's2')

      FactoryBot.create(:available_point, exercise: ex1)
      FactoryBot.create(:available_point, exercise: ex2)

      FactoryBot.create(:exercise, gdocs_sheet: 's2') # gets wrong course

      a = AvailablePoint.course_points_of_exercises(course, [ex2])
      expect(a).to eq(1)
      a = AvailablePoint.course_points_of_exercises(course, [ex1, ex2])
      expect(a).to eq(2)
    end
  end

  describe 'validation' do
    it 'checks against blanks in the name' do
      ap = FactoryBot.build(:available_point, name: 'foo ')
      expect(ap).not_to be_valid
      expect(ap.errors[:name].size).to eq(1)
    end
  end

  describe '#award_to' do
    it 'awards the point to the given user' do
      ap = FactoryBot.create(:available_point)
      user = FactoryBot.create(:user)
      ap.award_to(user)

      expect(user.awarded_points.size).to eq(1)
      aw = user.awarded_points.first
      expect(aw.name).to eq(ap.name)
      expect(aw.course_id).to eq(ap.exercise.course_id)
      expect(aw.submission).to be_nil
    end

    it 'is idempotent' do
      ap = FactoryBot.create(:available_point)
      user = FactoryBot.create(:user)
      ap.award_to(user)
      ap.award_to(user)
      ap.award_to(user)

      expect(user.awarded_points.size).to eq(1)
      aw = expect(user.awarded_points.first.name).to eq(ap.name)
    end
  end
end
