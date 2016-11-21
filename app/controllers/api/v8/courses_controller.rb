class Api::V8::CoursesController < Api::V8::BaseController

  include Swagger::Blocks

  swagger_path '/api/v8/courses/{course_id}/points' do
    operation :get do
      key :description, "Returns the course's points in a json format. Course is searched by id"
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_course_id'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'Points in json'
        schema do
          key :type, :array
          items do
            key :'$ref', :AwardedPointWithExerciseId
          end
        end
      end
    end
  end

  swagger_path '/api/v8/courses/{course_id}/points/user/{user_id}' do
    operation :get do
      key :description, "Returns the given user's points from the course in a json format. Course is searched by id"
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_course_id'
      parameter '$ref': '#/parameters/path_user_id'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'Points in json'
        schema do
          key :type, :array
          items do
            key :'$ref', :AwardedPointWithExerciseId
          end
        end
      end
    end
  end

  swagger_path '/api/v8/courses/{course_id}/points/user' do
    operation :get do
      key :description, "Returns the current user's points from the course in a json format. Course is searched by id"
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_course_id'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'Points in json'
        schema do
          key :type, :array
          items do
            key :'$ref', :AwardedPointWithExerciseId
          end
        end
      end
    end
  end

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/points' do
    operation :get do
      key :description, "Returns the course's points in a json format. Course is searched by name"
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'Points in json'
        schema do
          key :type, :array
          items do
            key :'$ref', :AwardedPointWithExerciseId
          end
        end
      end
    end
  end

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/points/user/{user_id}' do
    operation :get do
      key :description, "Returns the given user's points from the course in a json format. Course is searched by name"
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
      parameter '$ref': '#/parameters/path_user_id'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'Points in json'
        schema do
          key :type, :array
          items do
            key :'$ref', :AwardedPointWithExerciseId
          end
        end
      end
    end
  end

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}/points/user' do
    operation :get do
      key :description, "Returns the current user's points from the course in a json format. Course is searched by name"
      key :produces, ['application/json']
      key :tags, ['points']
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'Points in json'
        schema do
          key :type, :array
          items do
            key :'$ref', :AwardedPointWithExerciseId
          end
        end
      end
    end
  end

  swagger_path '/api/v8/courses/{course_id}' do
    operation :get do
      key :description, "Returns the course's information in a json format. Course is searched by id"
      key :produces, ['application/json']
      key :tags, ['course']
      parameter '$ref': '#/parameters/path_course_id'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'Course in json'
        schema do
          key :title, :course
          key :required, [:course]
          property :course, '$ref': :Course
        end
      end
    end
  end

  swagger_path '/api/v8/org/{organization_id}/courses/{course_name}' do
    operation :get do
      key :description, "Returns the course's information in a json format. Course is searched by organization id and course name"
      key :produces, ['application/json']
      key :tags, ['course']
      parameter '$ref': '#/parameters/path_organization_id'
      parameter '$ref': '#/parameters/path_course_name'
      response 403, '$ref': '#/responses/error'
      response 404, '$ref': '#/responses/error'
      response 200 do
        key :description, 'Course in json'
        schema do
          key :title, :course
          key :required, [:course]
          property :course, '$ref': :Course
        end
      end
    end
  end

  def get_points_all
    course = Course.find_by!(id: params[:course_id]) if params[:course_id]
    course ||= Course.find_by!(name: "#{params[:slug]}-#{params[:course_name]}")
    points = course.awarded_points.includes(:submission)
    authorize_collection :read, points
    present points.as_json_with_exercise_ids(course.exercises)
  end

  def get_points_user
    course = Course.find_by!(id: params[:course_id]) if params[:course_id]
    course ||= Course.find_by!(name: "#{params[:slug]}-#{params[:course_name]}")
    params[:user_id] = current_user.id unless params[:user_id]
    points = course.awarded_points.includes(:submission).where(user_id: params[:user_id])
    authorize_collection :read, points
    present points.as_json_with_exercise_ids(course.exercises)
  end

  def get_course
    unauthorize_guest!
    course = Course.find_by!(id: params[:course_id]) if params[:course_id]
    course ||= Course.find_by!(name: "#{params[:slug]}-#{params[:course_name]}")
    authorize! :read, course
    present course.course_as_json
  end
end
