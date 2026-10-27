# frozen_string_literal: true

require 'spec_helper'

describe ExerciseGroup, type: :model do
  let(:course) { FactoryBot.create(:course) }

  specify '#exercises' do
    ex = FactoryBot.create(:exercise, course: course, name: 'foo-bar-baz')
    ex2 = FactoryBot.create(:exercise, course: course, name: 'foo-bar-xaz')
    ex3 = FactoryBot.create(:exercise, course: course, name: 'xoo-bar-baz')
    another_course = FactoryBot.create(:course)
    ex4 = FactoryBot.create(:exercise, course: another_course, name: 'foo-bar-baz')

    expect(ex.exercise_group.exercises(false)).to include(ex)
    expect(ex.exercise_group.exercises(true)).to include(ex)
    expect(ex.exercise_group.parent.exercises(true)).to include(ex)
    expect(ex.exercise_group.parent.exercises(false)).not_to include(ex)

    expect(ex.exercise_group.exercises(false)).to include(ex2)
    expect(ex.exercise_group.exercises(false)).not_to include(ex3)
    expect(ex.exercise_group.exercises(false)).not_to include(ex4)

    expect(ex.exercise_group.parent.exercises(true)).to include(ex2)
    expect(ex.exercise_group.parent.exercises(true)).not_to include(ex3)
    expect(ex.exercise_group.parent.exercises(true)).not_to include(ex4)
  end

  describe '#group_unlock_conditions=' do
    let(:user) { FactoryBot.create(:user) }
    let!(:ex1) { FactoryBot.create(:exercise, course: course, name: 'week1-01') }
    let!(:ex2) { FactoryBot.create(:exercise, course: course, name: 'week1-02') }
    let!(:other) { FactoryBot.create(:exercise, course: course, name: 'week2-01') }
    let(:group) { course.exercise_group_by_name('week1') }

    before :each do
      [ex1, ex2, other].each do |ex|
        Unlock.create!(user: user, course: course, exercise_name: ex.name, valid_after: Time.zone.parse('2011-01-01'))
      end
    end

    it 'moves the date of existing unlock rows of the group' do
      group.group_unlock_conditions = ['5.5.2012'].to_json

      expect(Unlock.where(exercise_name: %w[week1-01 week1-02]).pluck(:valid_after)).to all(eq(Time.zone.parse('2012-05-05')))
      expect(Unlock.find_by(exercise_name: 'week2-01').valid_after).to eq(Time.zone.parse('2011-01-01'))
    end

    it 'keeps the date of unlock rows granted under other conditions' do
      group.group_unlock_conditions = ['1.1.2030'].to_json
      group.group_unlock_conditions = ['exercise week2-01'].to_json

      expect(Unlock.where(exercise_name: %w[week1-01 week1-02]).pluck(:valid_after)).to all(eq(Time.zone.parse('2030-01-01')))
    end

    it 'moves the date when only the order of the other conditions changes' do
      FactoryBot.create(:exercise, course: course, name: 'week3-01')
      group.group_unlock_conditions = ['exercise week2-01', 'exercise week3-01', '1.1.2030'].to_json
      group.group_unlock_conditions = ['exercise week3-01', 'exercise week2-01', '5.5.2012'].to_json

      expect(Unlock.where(exercise_name: %w[week1-01 week1-02]).pluck(:valid_after)).to all(eq(Time.zone.parse('2012-05-05')))
    end

    it 'leaves unlock rows alone when the conditions are cleared' do
      group.group_unlock_conditions = [].to_json

      expect(Unlock.where(exercise_name: %w[week1-01 week1-02]).pluck(:valid_after)).to all(eq(Time.zone.parse('2011-01-01')))
    end
  end

  describe '#exercises_by_unlock_spec' do
    let!(:ex1) { FactoryBot.create(:exercise, course: course, name: 'week1-01') }
    let!(:ex2) { FactoryBot.create(:exercise, course: course, name: 'week1-02') }
    let(:group) { course.exercise_group_by_name('week1') }

    it 'has one key when all exercises share the conditions' do
      expect(group.exercises_by_unlock_spec.keys).to eq([nil])
      group.group_unlock_conditions = ['5.5.2012'].to_json
      expect(group.exercises_by_unlock_spec.keys).to eq([['5.5.2012'].to_json])
    end

    it 'has a key per distinct set of conditions' do
      ex1.update!(unlock_spec: ['5.5.2012'].to_json)
      course.reload

      expect(course.exercise_group_by_name('week1').exercises_by_unlock_spec.transform_values { |es| es.map(&:name) })
        .to eq(['5.5.2012'].to_json => ['week1-01'], nil => ['week1-02'])
    end
  end
end
