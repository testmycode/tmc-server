class Api::V8::CoursesController < Api::V8::BaseController

  include Swagger::Blocks

  swagger_path "/api/v8/courses/{course_id}" do
    operation :get do
      key :description, "Returns the course's information in a json format. Course is searched by id"
      key :operationId, "getCourseById"
      key :produces, ["application/json"]
      key :tags, ["course"]
      parameter "$ref": "#/parameters/path_course_id"
      response 403, "$ref": "#/responses/error"
      response 404, "$ref": "#/responses/error"
      response 200 do
        key :description, "Course in json"
        schema do
          key :title, :course
          key :required, [:course]
          property :course, "$ref": :Course
        end
      end
    end
  end

  swagger_path "/api/v8/org/{organization_id}/courses/{course_name}" do
    operation :get do
      key :description, "Returns the course's information in a json format. Course is searched by organization id and course name"
      key :operationId, "getCourseByOrganizationIdAndCourseName"
      key :produces, ["application/json"]
      key :tags, ["course"]
      parameter "$ref": "#/parameters/path_organization_id"
      parameter "$ref": "#/parameters/path_course_name"
      response 403, "$ref": "#/responses/error"
      response 404, "$ref": "#/responses/error"
      response 200 do
        key :description, "Course in json"
        schema do
          key :title, :course
          key :required, [:course]
          property :course, "$ref": :Course
        end
      end
    end
  end

  def points
    course = find_by(Course, id: params[:id])
    points = course.awarded_points
    authorize! :read, points
    render json: points
  end

  def users_points
    user = find_by(User, id: params[:user_id])
    course = find_by(Course, id: params[:id])
    points = AwardedPoint.course_user_points(course, user)
    authorize! :read, points
    render json: points
  end

  def current_users_points
    course = find_by(Course, id: params[:id])
    points = AwardedPoint.course_user_points(course, current_user)
    authorize! :read, points
    render json: points
  end

  def find_by_name
    unauthorized_guest!
    course = find_by(Course, name: "#{params[:slug]}-#{params[:course_name]}")
    authorize! :read, course
    render json: course
  end

  def find_by_id
    unauthorized_guest!
    course = find_by(Course, id: params[:course_id])
    authorize! :read, course
    render json: course
  end

  def find_by(model, hash)
    course = model.find_by(hash)
    raise ActiveRecord::RecordNotFound, "Couldn't find #{model.name} with #{hash.map{|k,v| "#{k}=#{v}"}.join(', ')}" unless course
    course
  end
end
