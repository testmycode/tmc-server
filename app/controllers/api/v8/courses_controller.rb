class Api::V8::CoursesController < Api::V8::BaseController

  include Swagger::Blocks

  swagger_path "/api/v8/courses/{course_id}/points" do
    operation :get do
      key :description, "Returns the course's points in a json format. Course is searched by id"
      key :produces, ["application/json"]
      key :tags, ["course", "points"]
      parameter "$ref": "#/parameters/path_course_id"
      parameter "$ref": "#/parameters/path_user_id"
      response 403, "$ref": "#/responses/error"
      response 404, "$ref": "#/responses/error"
      response 200 do
        key :description, "Points in json"
        schema do
          key :type, :array
          items do
            key :"$ref", :AwardedPoint
          end
        end
      end
    end
  end

  swagger_path "/api/v8/courses/{course_id}/points/{user_id}" do
    operation :get do
      key :description, "Returns the given user's points from the course in a json format. Course is searched by id"
      key :produces, ["application/json"]
      key :tags, ["course", "points"]
      parameter "$ref": "#/parameters/path_course_id"
      parameter "$ref": "#/parameters/path_user_id"
      response 403, "$ref": "#/responses/error"
      response 404, "$ref": "#/responses/error"
      response 200 do
        key :description, "Points in json"
        schema do
          key :type, :array
          items do
            key :"$ref", :AwardedPoint
          end
        end
      end
    end
  end

  swagger_path "/api/v8/courses/{course_id}/points/mine" do
    operation :get do
      key :description, "Returns the current user's points from the course in a json format. Course is searched by id"
      key :produces, ["application/json"]
      key :tags, ["course", "points"]
      parameter "$ref": "#/parameters/path_course_id"
      response 403, "$ref": "#/responses/error"
      response 404, "$ref": "#/responses/error"
      response 200 do
        key :description, "Points in json"
        schema do
          key :type, :array
          items do
            key :"$ref", :AwardedPoint
          end
        end
      end
    end
  end

  swagger_path "/api/v8/courses/{course_id}" do
    operation :get do
      key :description, "Returns the course's information in a json format. Course is searched by id"
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
    render json: points.map {|p| p.point_as_json}
  end

  def users_points
    user = find_by(User, id: params[:user_id])
    course = find_by(Course, id: params[:id])
    points = AwardedPoint.course_user_points(course, user)
    authorize! :read, points
    render json: points.map {|p| p.point_as_json}
  end

  def current_users_points
    course = find_by(Course, id: params[:id])
    points = AwardedPoint.course_user_points(course, current_user)
    authorize! :read, points
    render json: points.map {|p| p.point_as_json}
  end

  def find_by_name
    unauthorized_guest!
    course = find_by(Course, name: "#{params[:slug]}-#{params[:course_name]}")
    authorize! :read, course
    render json: course.course_as_json
  end

  def find_by_id
    unauthorized_guest!
    course = find_by(Course, id: params[:course_id])
    authorize! :read, course
    render json: course.course_as_json
  end

  # TODO: Move to more accessible place
  # The intent of this is to make DB querying errors more descriptive and uniform
  def find_by(model, hash)
    course = model.find_by(hash)
    raise ActiveRecord::RecordNotFound, "Couldn't find #{model.name} with #{hash.map{|k,v| "#{k}=#{v}"}.join(', ')}" unless course
    course
  end
end
