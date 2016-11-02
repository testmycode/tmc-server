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

  swagger_path '/api/v8/organizations/{organization_id}/courses/{course_name}/exercises' do
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

  def get_by_course
    unauthorized_guest! if current_user.guest?
    course = Course.find_by(id: params[:id]) || Course.find_by(name: "#{params[:slug]}-#{params[:name]}")
    if course == nil
      authorize! :read, nil
      respond_not_found('Course not found!')
    else
      exercises = Exercise.where(course_id: course.id)
      exs = []
      auth_exs = []
      exercises.each do |ex|
        next unless ex.visible_to?(current_user)
        e = {}
        e[:id] = ex.id
        e[:name] = ex.name
        e[:publish_time] = ex.publish_time
        e[:solution_visible_after] = ex.solution_visible_after
        e[:deadline] = ex.deadline_for(current_user)
        e[:disabled] = ex.disabled?
        e[:available_points] = Exercise.find_by(id: ex.id).available_points
        exs.push(e)
        auth_exs.push(ex)
      end
      authorize! :read, auth_exs
      present(exs)
    end
  end


  #TODO: replace with methods from application_controller.rb made by rimi
  def unauthorized!(message = nil)
    raise CanCan::AccessDenied.new(message)
  end

  def unauthorized_guest!(message = "Authentication required")
    unauthorized!(message)
  end
end
