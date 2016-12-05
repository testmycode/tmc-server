module Api
  module V8
    class ApidocsController < ActionController::Base
      include Swagger::Blocks

      swagger_root do
        key :swagger, '2.0'
        info do
          key :version, '8'
          key :title, 'TMC API documentation'
          key :description, 'TMC API documentation'
          contact do
            key :name, 'TestMyCode'
            key :url, 'https://cs.helsinki.fi'
          end
          license do
            key :name, 'GPLv2'
          end
        end
        tag do
          key :name, 'api'
          key :description, 'API operations'
        end

        security_definition :api_key do
          key :type, :apiKey
          key :name, :Authorization
          key :in, :header
        end
        security do
          key :api_key, []
        end

        parameter :path_organization_id do
          key :name, :organization_id
          key :in, :path
          key :description, "Organization's id"
          key :required, true
          key :type, :string
        end
        parameter :path_course_id do
          key :name, :course_id
          key :in, :path
          key :description, "Course's id"
          key :required, true
          key :type, :integer
        end
        parameter :path_course_name do
          key :name, :course_name
          key :in, :path
          key :description, "Course's name"
          key :required, true
          key :type, :string
        end
        parameter :path_user_id do
          key :name, :user_id
          key :in, :path
          key :description, "User's id"
          key :required, true
          key :type, :integer
        end
        parameter :path_exercise_id do
          key :name, :exercise_id
          key :in, :path
          key :description, "Exercise's id"
          key :required, true
          key :type, :integer
        end
        parameter :path_exercise_name do
          key :name, :exercise_name
          key :in, :path
          key :description, "Exercise's name"
          key :required, true
          key :type, :string
        end
        response :error do
          key :description, 'An error occurred'
          schema do
            key :title, :errors
            key :description, 'A list of error messages'
            key :type, :array
            items do
              key :type, :string
            end
          end
        end
        key :host, 'localhost:3000'
        key :schemes, %w(http https)
        key :consumes, ['application/json']
        key :produces, ['application/json']
      end

      # A list of all classes that have swagger_* declarations.
      SWAGGERED_CLASSES = [
        Api::V8::CoursesController,
        Api::V8::Courses::PointsController,
        Api::V8::Courses::Users::PointsController,
        Api::V8::Courses::ExercisesController,
        Api::V8::Courses::Exercises::PointsController,
        Api::V8::Courses::Exercises::Users::PointsController,
        Api::V8::Courses::SubmissionsController,
        Api::V8::Courses::Users::SubmissionsController,
        Api::V8::Organizations::CoursesController,
        Api::V8::Organizations::Courses::PointsController,
        Api::V8::Organizations::Courses::Users::PointsController,
        Api::V8::Organizations::Courses::ExercisesController,
        Api::V8::Organizations::Courses::Exercises::PointsController,
        Api::V8::Organizations::Courses::Exercises::Users::PointsController,
        Api::V8::Organizations::Courses::SubmissionsController,
        Api::V8::Organizations::Courses::Users::SubmissionsController,
        Api::V8::ExercisesController,
        Api::V8::SubmissionsController,
        Api::V8::UsersController,
        Course,
        Exercise,
        AvailablePoint,
        Submission,
        AwardedPoint,
        User,
        self
      ].freeze

      def index
        render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
      end
    end
  end
end
