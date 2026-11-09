# typed: strict
# frozen_string_literal: true

module ExercisesHelper
  extend T::Sig
  sig { params(e: Exercise).returns(String) }
  def exercise_zip_url(e)
    exercise_url(e, format: 'zip').to_s
  end

  sig { params(e: Exercise).returns(String) }
  def exercise_solution_zip_url(e)
    exercise_solution_url(e, format: 'zip').to_s
  end

  sig { params(percentage: T.nilable(Integer)).returns(Integer) }
  def green(percentage)
    percentage || 0
  end

  sig { params(percentage_of_green: T.nilable(Integer)).returns(Integer) }
  def red(percentage_of_green)
    100 - (percentage_of_green || 100)
  end
end
