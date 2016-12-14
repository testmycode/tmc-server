module Api
  module V8
    module Core
      module Courses
        class ReviewsController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/core/courses/{course_id}/reviews' do
            operation :get do
              key :description, "Returns the course's review information for current user's submissions in a json format. Course is searched by id"
              key :produces, ['application/json']
              key :tags, ['review']
              parameter '$ref': '#/parameters/path_course_id'
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
              response 200 do
                schema do
                  key :description, "List of reviews for current user's submissions"
                  key :required, [ :reviews ]
                  property :reviews, type: :array do
                    items do
                      key :'$ref', :Review
                    end
                  end
                end
              end
            end
          end

          def index
            unauthorize_guest!
            course = Course.find_by!(id: params[:course_id])
            authorize! :read, course
            users_reviewed_submissions = course.submissions
                             .where(user_id: current_user.id)
                             .where('requests_review OR requires_review OR reviewed')
                             .order('created_at DESC')

            present Review.course_reviews_json(course, users_reviewed_submissions, view_context)
          end
        end
      end
    end
  end
end
