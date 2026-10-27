# frozen_string_literal: true

module Api
  module V8
    module Courses
      class ExercisesController < Api::V8::BaseController
        include Swagger::Blocks

        swagger_path '/api/v8/courses/{course_id}/exercises' do
          operation :get do
            key :description, 'Returns all exercises of the course as json. Course is searched by id'
            key :operationId, 'findExercisesById'
            key :produces, ['application/json']
            key :tags, ['exercise']
            parameter '$ref': '#/parameters/path_course_id'
            response 200 do
              key :description, 'Exercises in json'
              schema do
                key :title, :exercises
                key :required, [:exercises]
                property :exercises do
                  key :type, :array
                  items do
                    key :'$ref', :ExerciseWithPoints
                  end
                end
              end
            end
            response 403, '$ref': '#/responses/error'
            response 404, '$ref': '#/responses/error'
          end
        end

        def index
          unauthorize_guest!
          course = Course.find_by!(id: params[:course_id]) if params[:course_id]
          can_see_everything = current_user.administrator? || current_user.teacher?(course.organization) || current_user.assistant?(course)
          authorize! :read, course

          if can_see_everything
            unlocked_ids = course.exercises.pluck(:id).to_set
          else
            exercises = course.exercises.where(hidden: false, disabled_status: 0).to_a
            unlocked_names = course.unlocked_exercise_names_for(current_user, exercises)
            unlocked_ids = exercises.select { |ex| unlocked_names.include?(ex.name) }.to_set(&:id)
          end

          all_exercises = course.exercises.includes(:available_points).where(disabled_status: 0)
          unless can_see_everything
            all_exercises = course.exercises
                                  .includes(:available_points)
                                  .where(hidden: false)
                                  .select(&:_fast_visible?)
          end

          all_awarded_points = AwardedPoint.course_user_points(course, current_user).includes(:submission)

          presentable = all_exercises.map do |ex|
            points_visible = ex.points_visible_to?(current_user)
            available_points = ex.available_points
            available_points_names = available_points.map(&:name)
            awarded_points = all_awarded_points.select { |awp| available_points_names.include?(awp.name) }.map(&:name)
            {
              id: ex.id,
              available_points: points_visible ? available_points : [],
              awarded_points: points_visible ? awarded_points : [],
              name: ex.name,
              publish_time: ex.publish_time,
              solution_visible_after: ex.solution_visible_after,
              deadline: ex.deadline_for(current_user),
              soft_deadline: ex.soft_deadline_for(current_user),
              disabled: ex.disabled?,
              unlocked: unlocked_ids.include?(ex.id)
            }
          end

          render json: presentable
        end
      end
    end
  end
end
