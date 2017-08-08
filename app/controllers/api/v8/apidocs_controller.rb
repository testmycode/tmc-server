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
            key :url, 'https://www.gnu.org/licenses/gpl-2.0.html'
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
        parameter :path_submission_id do
          key :name, :submission_id
          key :in, :path
          key :description, "Submission's id"
          key :required, true
          key :type, :integer
        end
        parameter :review_body do
          key :name, 'review[review_body]'
          key :in, :formData
          key :description, "Review's body"
          key :required, true
          key :type, :string
        end
        parameter :points do
          key :name, 'review[points]'
          key :in, :formData
          key :description, 'Points for submission'
          key :type, :string
        end
        parameter :path_review_id do
          key :name, :review_id
          key :in, :path
          key :description, "Review's id"
          key :required, true
          key :type, :integer
        end
        parameter :header_update_review do
          key :name, 'review[review_body]'
          key :in, :formData
          key :description, 'Update review text'
          key :required, false
          key :type, :string
        end
        parameter :header_mark_review_as_read do
          key :name, :mark_as_read
          key :in, :formData
          key :description, 'Mark review as read'
          key :required, false
          key :type, :string
        end
        parameter :header_mark_review_as_unread do
          key :name, :mark_as_unread
          key :in, :formData
          key :description, 'Mark review as unread'
          key :required, false
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
      # The order of the swagered_classes affects the order they are shown in swaggerUI
      SWAGGERED_CLASSES = [
        Api::V8::SubmissionsController,
        Api::V8::UsersController,
        Api::V8::CoursesController,
        Api::V8::Courses::PointsController,
        Api::V8::Courses::SubmissionsController,
        Api::V8::Courses::ExercisesController,
        Api::V8::Courses::Exercises::PointsController,
        Api::V8::Courses::Exercises::Users::PointsController,
        Api::V8::Courses::Users::PointsController,
        Api::V8::Courses::Users::SubmissionsController,
        Api::V8::OrganizationsController,
        Api::V8::Organizations::CoursesController,
        Api::V8::Organizations::Courses::PointsController,
        Api::V8::Organizations::Courses::SubmissionsController,
        Api::V8::Organizations::Courses::ExercisesController,
        Api::V8::Organizations::Courses::Exercises::PointsController,
        Api::V8::Organizations::Courses::Exercises::Users::PointsController,
        Api::V8::Organizations::Courses::Users::PointsController,
        Api::V8::Organizations::Courses::Users::SubmissionsController,
        Api::V8::Core::CoursesController,
        Api::V8::Core::Courses::ReviewsController,
        Api::V8::Core::Courses::UnlocksController,
        Api::V8::Core::ExercisesController,
        Api::V8::Core::Exercises::SolutionsController,
        Api::V8::Core::Exercises::SubmissionsController,
        Api::V8::Core::Organizations::CoursesController,
        Api::V8::Core::SubmissionsController,
        Api::V8::Core::Submissions::ReviewsController,
        AvailablePoint,
        AwardedPoint,
        Course,
        Exercise,
        Organization,
        Review,
        Submission,
        User,
        self
      ].freeze

      def index
        render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
      end
    end
  end
end
