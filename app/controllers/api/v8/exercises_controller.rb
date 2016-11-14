class Api::V8::ExercisesController < Api::V8::BaseController
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
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
    end
  end

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/exercises' do
    operation :get do
      key :description, 'Returns all exercises of the course as json. Course is searched by name'
      key :operationId, 'findExercisesByName'
      key :produces, ['application/json']
      key :tags, ['exercise']
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
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
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course or organization not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
    end
  end

  swagger_path '/api/v8/courses/{course_id}/exercises/{exercise_name}/points' do
    operation :get do
      key :description, 'Returns all the awarded points of an excercise for all users'
      key :operationId, 'findAllAwardedPointsByCourseIdAndExerciseName'
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_course_id'
      parameter '$ref': '#/parameters/path_exercise_name'
      response 200 do
        key :description, 'Awarded points in json'
        schema do
          key :title, :points
          key :required, [:points]
          property :points do
            key :type, :array
            items do
              key :'$ref', :AvailablePoint
            end
          end
        end
      end
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course or exercise not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
    end
  end

  swagger_path '/api/v8/courses/{course_id}/exercises/{exercise_name}/points/user' do
    operation :get do
      key :description, 'Returns all the awarded points of an excercise for current user'
      key :operationId, 'findCurrentUsersAwardedPointsByCourseIdAndExerciseName'
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_course_id'
      parameter '$ref': '#/parameters/path_exercise_name'
      response 200 do
        key :description, 'Awarded points in json'
        schema do
          key :title, :points
          key :required, [:points]
          property :points do
            key :type, :array
            items do
              key :'$ref', :AvailablePoint
            end
          end
        end
      end
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course or exercise not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
    end
  end

  swagger_path '/api/v8/courses/{course_id}/exercises/{exercise_name}/points/user/{user_id}' do
    operation :get do
      key :description, 'Returns all the awarded points of an excercise for the specified user'
      key :operationId, 'findUsersAwardedPointsByCourseIdAndExerciseName'
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_course_id'
      parameter '$ref': '#/parameters/path_exercise_name'
      parameter '$ref': '#/parameters/path_user_id'
      response 200 do
        key :description, 'Awarded points in json'
        schema do
          key :title, :points
          key :required, [:points]
          property :points do
            key :type, :array
            items do
              key :'$ref', :AvailablePoint
            end
          end
        end
      end
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course, exercise or user not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
    end
  end

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/exercises/{exercise_name}/points' do
    operation :get do
      key :description, 'Returns all the awarded points of an excercise for all users'
      key :operationId, 'findAllAwardedPointsByCourseNameAndExerciseName'
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
      parameter '$ref': '#/parameters/path_exercise_name'
      response 200 do
        key :description, 'Awarded points in json'
        schema do
          key :title, :points
          key :required, [:points]
          property :points do
            key :type, :array
            items do
              key :'$ref', :AvailablePoint
            end
          end
        end
      end
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course or exercise not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
    end
  end

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/exercises/{exercise_name}/points/user' do
    operation :get do
      key :description, 'Returns all the awarded points of an excercise for current user'
      key :operationId, 'findCurrentUsersAwardedPointsByCourseNameAndExerciseName'
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
      parameter '$ref': '#/parameters/path_exercise_name'
      response 200 do
        key :description, 'Awarded points in json'
        schema do
          key :title, :points
          key :required, [:points]
          property :points do
            key :type, :array
            items do
              key :'$ref', :AvailablePoint
            end
          end
        end
      end
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course or exercise not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
    end
  end

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/exercises/{exercise_name}/points/user/{user_id}' do
    operation :get do
      key :description, 'Returns all the awarded points of an excercise for the specified user'
      key :operationId, 'findUsersAwardedPointsByCourseNameAndExerciseName'
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
      parameter '$ref': '#/parameters/path_exercise_name'
      parameter '$ref': '#/parameters/path_user_id'
      response 200 do
        key :description, 'Awarded points in json'
        schema do
          key :title, :points
          key :required, [:points]
          property :points do
            key :type, :array
            items do
              key :'$ref', :AvailablePoint
            end
          end
        end
      end
      response 403, '$ref': '#/responses/auth_required'
      response 404 do
        key :description, 'Course, exercise or user not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
    end
  end

  def get_by_course
    unauthorize_guest!
    course = Course.find_by!(id: params[:course_id]) if params[:course_id]
    course ||= Course.find_by!(name: "#{params[:slug]}-#{params[:course_name]}")
    exercises = Exercise.includes(:available_points).where(course_id: course.id)

    visible = exercises.select { |ex| ex.visible_to?(current_user) }
    presentable = visible.map do |ex|
      {
          id: ex.id,
          available_points: ex.available_points,
          name: ex.name,
          publish_time: ex.publish_time,
          solution_visible_after: ex.solution_visible_after,
          deadline: ex.deadline_for(current_user),
          disabled: ex.disabled?
      }
    end

    authorize_collection :read, visible
    present(presentable)

  end

  def download
    course = Course.find_by!(name: "#{params[:slug]}-#{params[:course_name]}")
    exercise = Exercise.find_by!(name: params[:exercise_name], course_id: course.id)

    authorize! :download, exercise
    send_file exercise.stub_zip_file_path
  end

  def get_points_user
    course = Course.find_by!(id: params[:id]) if params[:id]
    course ||= Course.find_by!(name: "#{params[:slug]}-#{params[:name]}")
    params[:user_id] = current_user.id unless params[:user_id]

    points = AwardedPoint.includes(:submission)
      .where(submissions: {exercise_name: params[:exercise_name]},
             course_id: course.id,
             user_id: params[:user_id])
    authorize! :read, points
    present(AwardedPoint.points_json_with_exercise_id(points, course.exercises))
  end

  def get_points_all
    course = Course.find_by!(id: params[:id]) if params[:id]
    course ||= Course.find_by!(name: "#{params[:slug]}-#{params[:name]}")

    points = AwardedPoint.includes(:submission)
                 .where(submissions: {exercise_name: params[:exercise_name]},
                        course_id: course.id)
    authorize! :read, points
    present(AwardedPoint.points_json_with_exercise_id(points, course.exercises))
  end
end
