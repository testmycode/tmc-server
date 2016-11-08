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

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/exercises/{exercise_name}/download' do
    operation :get do
      key :description, 'Download the exercise as a zip file'
      key :operationId, 'downloadExercise'
      key :produces, ['application/zip']
      key :tags, ['exercise']
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
      parameter '$ref': '#/parameters/path_exercise_name'
      response 200 do
        key :description, 'Exercise zip file'
        schema do
          key :type, :file
        end
      end
      response 404 do
        key :description, 'Course or exercise not found'
        schema do
          key :title, :errors
          key :type, :json
        end
      end
    end
  end

  def get_by_course
    unauthorized_guest! if current_user.guest?

    course = Course.find_by!(id: params[:id]) || Course.find_by!(name: "#{params[:slug]}-#{params[:name]}")
    exercises = Exercise.where(course_id: course.id)

    visible = exercises.select { |ex| ex.visible_to?(current_user) }
    presentable = visible.map do |ex|
      {
          id: ex.id,
          available_points: Exercise.find_by(id: ex.id).available_points,
          name: ex.name,
          publish_time: ex.publish_time,
          solution_visible_after: ex.solution_visible_after,
          deadline: ex.deadline_for(current_user),
          disabled: ex.disabled?
      }
    end
    authorize! :read, visible
    present(presentable)

  end

  def download
    self.class.skip_authorization_check
    course = Course.find_by!(name: "#{params[:slug]}-#{params[:name]}")
    exercise = Exercise.find_by!(name: params[:exercise_name], course_id: course.id)

    authorize! :download, exercise
    send_file exercise.stub_zip_file_path
  end
end
