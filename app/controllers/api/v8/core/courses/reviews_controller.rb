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
              key :tags, ['core']
              parameter '$ref': '#/parameters/path_course_id'
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
              response 200 do
                key :description, "List of reviews for current user's submissions"
                schema do
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

          swagger_path '/api/v8/core/courses/{course_id}/reviews/{review_id}' do
            operation :put do
              key :description, "Update existing review. Review text can be updated by using 'review[review_body]: 'some review here'' in parameters.
                                 Review can be marked as read by setting 'mark_as_read' parameter to true, and unread by using parameter 'mark_as_unread'"
              key :produces, ['application/json']
              key :tags, ['core']
              parameter '$ref': '#/parameters/path_course_id'
              parameter '$ref': '#/parameters/path_review_id'
              parameter '$ref': '#/parameters/header_update_review'
              parameter '$ref': '#/parameters/header_mark_review_as_read'
              parameter '$ref': '#/parameters/header_mark_review_as_unread'
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
              response 200 do
                key :description, "Returns status 'OK' if successful"
                schema do
                  property :status, type: :string, example: 'OK'
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

          def update
            if params[:review].is_a?(Hash)
              update_review
            elsif params[:mark_as_read]
              mark_as_read(true)
            elsif params[:mark_as_unread]
              mark_as_read(false)
            end
          end

          def update_review
            fetch :review
            authorize! :update, @review
            @review.review_body = params[:review][:review_body]

            begin
              mark_as_reviewed
              award_points
              @review.submission.save!
              @review.save!
            rescue
              ::Rails.logger.error($!)
              respond_with_error('Failed to save code review.')
            else
              present({ status: 200 }) and return
            end
          end

          def mark_as_read(read)
            fetch :review
            authorize! (read ? :mark_as_read : :mark_as_unread), @review

            @review.marked_as_read = read
            if @review.save
              present({ status: 200 }) and return
            end
          end

          def fetch(*stuff)
            if stuff.include? :course
              @course = Course.find(params[:course_id])
              authorize! :read, @course
            end
            if stuff.include? :submission
              @submission = Submission.find(params[:submission_id])
              authorize! :read, @submission
            end
            if stuff.include? :review
              @review = Review.find(params[:id])
              authorize! :read, @review
            end
            if stuff.include? :files
              @files = SourceFileList.for_submission(@submission)
            end
          end

          def mark_as_reviewed
            sub = @review.submission
            sub.reviewed = true
            sub.review_dismissed = false
            sub.of_same_kind
                .where('(requires_review OR requests_review) AND NOT reviewed')
                .where(['created_at < ?', sub.created_at])
                .update_all(newer_submission_reviewed: true)
          end

          def award_points
            submission = @review.submission
            exercise = submission.exercise
            course = exercise.course
            fail 'Exercise of submission has been moved or deleted' unless exercise

            available_points = exercise.available_points.where(requires_review: true).map(&:name)
            previous_points = course.awarded_points.where(user_id: submission.user_id, name: available_points).map(&:name)

            new_points = []
            if params[:review][:points].respond_to?(:keys)
              for point_name in params[:review][:points].keys
                unless exercise.available_points.where(name: point_name).any?
                  fail "Point does not exist: #{point_name}"
                end

                new_points << point_name
                pt = submission.awarded_points.build(
                    course_id: submission.course_id,
                    user_id: submission.user_id,
                    name: point_name
                )
                authorize! :create, pt
                pt.save!
              end
            end

            @review.points = (@review.points_list + new_points + previous_points).uniq.natsort.join(' ')
            submission.points = (submission.points_list + new_points + previous_points).uniq.natsort.join(' ')
          end
        end
      end
    end
  end
end
