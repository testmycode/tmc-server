require 'spec_helper'

describe ExerciseGroup do
  let(:course) { Factory.create(:course) }

  specify "#exercises" do
    ex = Factory.create(:exercise, :course => course, :name => 'foo-bar-baz')
    ex2 = Factory.create(:exercise, :course => course, :name => 'foo-bar-xaz')
    ex3 = Factory.create(:exercise, :course => course, :name => 'xoo-bar-baz')
    another_course = Factory.create(:course)
    ex4 = Factory.create(:exercise, :course => another_course, :name => 'foo-bar-baz')

    ex.exercise_group.exercises(false).should include(ex)
    ex.exercise_group.exercises(true).should include(ex)
    ex.exercise_group.parent.exercises(true).should include(ex)
    ex.exercise_group.parent.exercises(false).should_not include(ex)

    ex.exercise_group.exercises(false).should include(ex2)
    ex.exercise_group.exercises(false).should_not include(ex3)
    ex.exercise_group.exercises(false).should_not include(ex4)

    ex.exercise_group.parent.exercises(true).should include(ex2)
    ex.exercise_group.parent.exercises(true).should_not include(ex3)
    ex.exercise_group.parent.exercises(true).should_not include(ex4)
  end
end
