require 'natsort'

class Review < ActiveRecord::Base
  include Swagger::Blocks

  swagger_schema :Review do
    key :required, [ :submission_id, :exercise_name, :id, :marked_as_read, :reviewer_name, :review_body,
                     :points, :points_not_awarded, :url, :update_url, :created_at, :updated_at]

    property :submission_id, type: :integer, example: 1
    property :exercise_name, type: :string, example: "trivial"
    property :id, type: :integer, example: 1
    property :marked_as_read, type: :boolean, example: false
    property :reviewer_name, type: :string, example: "hn"
    property :review_body, type: :string, example: ""
    property :points, type: :array do
      items do
        key :type, :string
      end
    end
    property :points_not_awarded, type: :array do
      items do
        key :type, :string
      end
    end
    property :url, type: :string, example: "http://localhost:3000/submissions/1/reviews"
    property :update_url, type: :string, example: "http://localhost:3000/reviews"
    property :created_at, type: :string, example: "2016-10-10T13:22:19.554+03:00"
    property :updated_at, type: :string, example: "2016-10-10T13:22:19.554+03:00"
  end

  def self.course_reviews_json(course, reviewed_submissions, view_context)
    reviewed_submissions = reviewed_submissions.includes(reviews: [:reviewer, :submission])
    exercises = Hash[course.exercises.map { |e| [e.name, e] }]
    reviewed_submissions.map do |s|
      s.reviews.map do |r|
        available_points = exercises[r.submission.exercise_name].available_points.where(requires_review: true).map(&:name)
        points_not_awarded = available_points - r.points_list
        {
            submission_id: s.id,
            exercise_name: s.exercise_name,

            id: r.id,
            marked_as_read: r.marked_as_read,
            reviewer_name: r.reviewer.display_name,
            review_body: r.review_body,
            points: r.points_list.natsort,
            points_not_awarded: points_not_awarded.natsort,
            url: view_context.submission_reviews_url(r.submission_id),
            update_url: view_context.api_v8_core_course_review_url(course.id, r.id),
            created_at: r.created_at,
            updated_at: r.updated_at,
        }
      end
    end.flatten
  end

  belongs_to :submission
  belongs_to :reviewer, class_name: 'User', inverse_of: :reviews

  def points_list
    points.to_s.split
  end

  def readable_by?(user)
    user.administrator? ||
        user.id == submission.user.id ||
        user.teacher?(submission.course.organization)
  end

  def manageable_by?(user)
    user.administrator? ||
        user.teacher?(submission.course.organization)
  end
end
