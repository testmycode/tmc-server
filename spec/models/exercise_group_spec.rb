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
end
