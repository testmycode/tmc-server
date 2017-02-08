module Api
  module V8
    module Core
      module Submissions
        class ReviewsController < Api::V8::BaseController
          include Swagger::Blocks

          swagger_path '/api/v8/core/submissions/{submission_id}/reviews' do
            operation :post do
              key :description, 'Submits a review for the submission'
              key :operationId, 'submitReview'
              key :produces, ['application/json']
              key :tags, ['core']
              parameter '$ref': '#/parameters/path_submission_id'
              parameter '$ref': '#/parameters/review_body'
              parameter '$ref': '#/parameters/points'
              response 200 do
                key :description, 'Submits a new review'
                schema do
                  key :title, :status
                  key :required, [:status]
                  property :status, type: :string, example: 'ok'
                end
              end
              response 403, '$ref': '#/responses/error'
              response 404, '$ref': '#/responses/error'
            end
          end

          around_action :wrap_transaction

          def create
            unauthorize_guest!
            submission = Submission.find(params[:submission_id])
            authorize! :read, submission

            @review = Review.new(
              submission_id: submission.id,
              reviewer_id: current_user.id,
              review_body: params[:review][:review_body]
            )

            authorize! :create_review, submission.course

            begin
              ActiveRecord::Base.connection.transaction do
                award_points
                mark_as_reviewed
                @review.submission.save!
                @review.save!
              end
            rescue
              ::Rails.logger.error($!)
              respond_with_error('Failed to save code review.')
            else
              notify_user_about_new_review
              send_email_about_new_review if params[:send_email]
              present(status: 'ok')
            end
          end

          private

          def award_points
            submission = @review.submission
            exercise = submission.exercise
            course = exercise.course
            fail 'Exercise of submission has been moved or deleted' unless exercise

            available_points = exercise.available_points.where(requires_review: true).map(&:name)
            previous_points = course.awarded_points.where(user_id: submission.user_id, name: available_points).map(&:name)

            new_points = []
            if params[:review][:points].respond_to?(:keys)
              params[:review][:points].keys.each do |point_name|
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

          def mark_as_reviewed
            sub = @review.submission
            sub.reviewed = true
            sub.review_dismissed = false
            sub.of_same_kind
              .where('(requires_review OR requests_review) AND NOT reviewed')
              .where(['created_at < ?', sub.created_at])
              .update_all(newer_submission_reviewed: true)
          end

          def notify_user_about_new_review
            channel = '/broadcast/user/' + @review.submission.user.username + '/review-available'
            data = {
              exercise_name: @review.submission.exercise_name,
              url: submission_reviews_url(@review.submission),
              points: @review.points_list
            }
            CometServer.get.try_publish(channel, data)
          end

          def send_email_about_new_review
            ReviewMailer.review_email(@review).deliver
          end
        end
      end
    end
  end
end
