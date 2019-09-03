# frozen_string_literal: true

module Api
  module V8
    module Exercises
      class ModelSolutionsController < Api::V8::BaseController
        def index
          unauthorize_guest!
          exercise = Exercise.find(params[:exercise_id])
          course = exercise.course
          authorize! :read, exercise
          solution = exercise.solution
          begin
            authorize! :read, solution
          rescue CanCan::AccessDenied
            model_solution_token_used_on_this_exercise = ModelSolutionTokenUsed.where(user: current_user, course: course, exercise_name: exercise.name).count > 0
            grant_model_solution_token_every_nth_completed_exercise = course.grant_model_solution_token_every_nth_completed_exercise
            if grant_model_solution_token_every_nth_completed_exercise && grant_model_solution_token_every_nth_completed_exercise > 0 && !model_solution_token_used_on_this_exercise
              completed_exercises_count = course.submissions.where(all_tests_passed: true, user: current_user).distinct.select(:exercise_name).count
              total_model_solution_tokens = (completed_exercises_count / grant_model_solution_token_every_nth_completed_exercise) + course.initial_coin_stash

              tokens_used = ModelSolutionTokenUsed.where(user: current_user, course: course).count
              available_model_solution_tokens = total_model_solution_tokens - tokens_used
              if available_model_solution_tokens > 0
                ModelSolutionTokenUsed.create!(user: current_user, course: course, exercise_name: exercise.name)
              else
                raise CanCan::AccessDenied
              end
            else
              raise CanCan::AccessDenied unless model_solution_token_used_on_this_exercise
            end
          end
          ModelSolutionAccessLog.create!(user: current_user, course: course, exercise_name: exercise.name)
          present(
            exercise: {
              id: exercise.id
            },
            solution: {
              files: solution.files
            }
          )
        end
      end
    end
  end
end
