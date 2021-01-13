# frozen_string_literal: true

require 'spec_helper'

describe UnlockSpec, type: :model do
  let!(:course) { FactoryBot.create(:course) }
  let!(:ex1) { FactoryBot.create(:exercise, course: course, name: 'grp-ex1') }
  let!(:ex2) { FactoryBot.create(:exercise, course: course, name: 'grp-ex2') }
  let!(:ex3) { FactoryBot.create(:exercise, course: course, name: 'ex3') }
  let!(:ex1_pt1) { FactoryBot.create(:available_point, course: course, exercise: ex1, name: 'ex1_pt1') }
  let!(:ex1_pt2) { FactoryBot.create(:available_point, course: course, exercise: ex1, name: 'ex1_pt2') }
  let!(:ex2_pt1) { FactoryBot.create(:available_point, course: course, exercise: ex2, name: 'ex2_pt1') }
  let!(:ex2_pt2) { FactoryBot.create(:available_point, course: course, exercise: ex2, name: 'ex2_pt2') }
  let!(:ex2_pt3) { FactoryBot.create(:available_point, course: course, exercise: ex2, name: 'ex2_pt3') }
  let!(:user) { FactoryBot.create(:user) }

  def award(*pts)
    pts.each do |pt|
      available = send(pt)
      FactoryBot.create(
        :awarded_point,
        course: available.course,
        name: available.name,
        user: user
      )
    end
  end

  def call_parsable(spec)
    UnlockSpec.parsable?(spec.to_json, ex1)
  end

  RSpec::Matchers.define :permit_unlock_for do |user|
    match do |unlock_spec|
      unlock_spec.permits_unlock_for?(user)
    end
  end

  specify 'empty' do
    spec = UnlockSpec.new(course, [])
    expect(spec.valid_after).to be_nil
    expect(spec).to permit_unlock_for(user)
  end

  specify 'unlocked_after: <date>' do
    spec = UnlockSpec.new(course, ['12.12.2012'])
    expect(spec.valid_after).to eq(Date.parse('2012-12-12').in_time_zone)
    expect(spec).to permit_unlock_for(user)
  end

  specify 'unlocked_after: exercise <exercise>' do
    award(:ex1_pt1, :ex1_pt2, :ex2_pt1, :ex2_pt3)

    expect(UnlockSpec.new(course, ['exercise grp-ex1'])).to permit_unlock_for(user)
    expect(UnlockSpec.new(course, ['exercise grp-ex2'])).not_to permit_unlock_for(user)
  end

  specify 'unlocked_after: exercise group <exercise>' do
    spec = UnlockSpec.new(course, ['exercise group grp'])
    expect(spec).not_to permit_unlock_for(user)
    award(:ex1_pt1, :ex1_pt2, :ex2_pt1, :ex2_pt2)
    expect(spec).not_to permit_unlock_for(user)
    award(:ex2_pt3)
    expect(spec).to permit_unlock_for(user)
  end

  specify 'unlocked_after: point ex1_pt2' do
    spec = UnlockSpec.new(course, ['point ex1_pt2'])
    expect(spec).not_to permit_unlock_for(user)
    award(:ex1_pt2)
    expect(spec).to permit_unlock_for(user)
  end

  specify 'unlocked_after: points ex1_pt2 ex2_pt2' do
    spec = UnlockSpec.new(course, ['points ex1_pt2 ex2_pt2'])
    expect(spec).not_to permit_unlock_for(user)
    award(:ex1_pt2)
    expect(spec).not_to permit_unlock_for(user)
    award(:ex2_pt2)
    expect(spec).to permit_unlock_for(user)
  end

  specify 'unlocked_after: <n>% of <exercise>' do
    award(:ex1_pt1, :ex1_pt2, :ex2_pt1, :ex2_pt3)

    expect(UnlockSpec.new(course, ['50% of grp-ex1'])).to permit_unlock_for(user)
    expect(UnlockSpec.new(course, ['100% of grp-ex1'])).to permit_unlock_for(user)
    expect(UnlockSpec.new(course, ['100% of grp-ex2'])).not_to permit_unlock_for(user)
    expect(UnlockSpec.new(course, ['60% of grp-ex2'])).to permit_unlock_for(user)
  end

  specify 'unlocked_after: <n>% of <exercise_group>' do
    award(:ex1_pt1, :ex1_pt2, :ex2_pt1)

    expect(UnlockSpec.new(course, ['50% of grp'])).to permit_unlock_for(user)
    expect(UnlockSpec.new(course, ['70% of grp'])).not_to permit_unlock_for(user)
  end

  specify 'unlocked_after: <n> exercises in <exercise_group>' do
    FactoryBot.create(:submission, user: user, course: course, exercise: ex1, all_tests_passed: true)
    FactoryBot.create(:submission, user: user, course: course, exercise: ex2, all_tests_passed: false)
    award(:ex1_pt1, :ex1_pt2, :ex2_pt1)

    expect(UnlockSpec.new(course, ['1 exercise in grp'])).to permit_unlock_for(user)
    expect(UnlockSpec.new(course, ['2 exercises in grp'])).not_to permit_unlock_for(user)
  end

  specify 'unlocked_after: <n> points in <exercise>' do
    award(:ex1_pt1, :ex1_pt2, :ex2_pt1, :ex2_pt3)

    expect(UnlockSpec.new(course, ['2 points in grp-ex1'])).to permit_unlock_for(user)
    expect(UnlockSpec.new(course, ['3 points in grp-ex1'])).not_to permit_unlock_for(user)
    expect(UnlockSpec.new(course, ['2 points in grp-ex2'])).to permit_unlock_for(user)
    expect(UnlockSpec.new(course, ['3 points in grp-ex2'])).not_to permit_unlock_for(user)

    expect(UnlockSpec.new(course, ['3 points in grp-ex2']).description_for(user)).to eq(
      'To unlock this exercise, you must get 1 more point from grp-ex2.'
    )
  end

  specify 'unlocked_after: <n> points in <exercise_group>' do
    award(:ex1_pt1, :ex1_pt2, :ex2_pt1, :ex2_pt3)

    expect(UnlockSpec.new(course, ['4 points in grp'])).to permit_unlock_for(user)
    expect(UnlockSpec.new(course, ['5 points in grp'])).not_to permit_unlock_for(user)
  end

  describe 'unlocked_after: <multiple conditions>' do
    it 'should require all to be true' do
      award(:ex1_pt1, :ex1_pt2, :ex2_pt1, :ex2_pt3)
      FactoryBot.create(:submission, user: user, course: course, exercise: ex1, all_tests_passed: true)

      expect(UnlockSpec.new(course, ['2 points in grp-ex1', '1 exercise in grp'])).to permit_unlock_for(user)
      expect(UnlockSpec.new(course, ['3 points in grp-ex1', '1 exercise in grp'])).not_to permit_unlock_for(user)
      expect(UnlockSpec.new(course, ['2 points in grp-ex1', '2 exercise in grp'])).not_to permit_unlock_for(user)
    end
  end

  describe 'parsable?' do
    it 'should return true if spec is valid' do
      expect(call_parsable(['1.1.2000'])).to eq(true)
      expect(call_parsable(['1 exercise in grp'])).to eq(true)
      expect(call_parsable(['60% of grp-ex2'])).to eq(true)
      expect(call_parsable(['50% of grp'])).to eq(true)
      expect(call_parsable(['5 points in grp'])).to eq(true)
      expect(call_parsable(['2 points in grp-ex1'])).to eq(true)
      expect(call_parsable(['1.1.2000', '1 exercise in grp'])).to eq(true)
      expect(call_parsable(['20% of grp', '50% of grp', '80% of grp'])).to eq(true)
    end

    it 'should raise error if spec is invalid' do
      expect { call_parsable(['1.1.100000']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['1.1.0000']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['1 exercise in nonexistent']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['60% of grp-nonexistent']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['60% of grp-']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['60% of gr']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['60% of grp-ex']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['60% of grp-ex2-']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['60% if grp-ex2']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['foo']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['foo', '1.1.2000']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
      expect { call_parsable(['2.2.2000', '1.1.2000']) }.to raise_error(UnlockSpec::InvalidSyntaxError)
    end
  end
end
