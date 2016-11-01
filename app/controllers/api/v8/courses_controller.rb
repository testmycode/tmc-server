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

  swagger_path "/api/v8/organizations/{organization_id}/courses/{course_name}" do
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

  def find_by_name
    unauthorized_guest! if current_user.guest?
    course_name = "#{params[:slug]}-#{params[:name]}"
    course = Course.find_by(name: course_name)
    raise ActiveRecord::RecordNotFound, "Couldn't find Course with name #{course_name}" unless course
    show_json(course)
  end

  def find_by_id
    unauthorized_guest! if current_user.guest?
    course_id = params[:id]
    course = Course.find_by_id(course_id)
    raise ActiveRecord::RecordNotFound, "Couldn't find Course with id #{course_id}" unless course
    show_json(course)
  end

  def show_json(course)
    authorize! :read, course
    present(course)
  end
end
