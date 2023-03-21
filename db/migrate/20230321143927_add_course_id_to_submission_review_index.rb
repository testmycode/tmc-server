class AddCourseIdToSubmissionReviewIndex < ActiveRecord::Migration[6.1]
  def change
    remove_index :submissions, column: [:requires_review, :requests_review], name: "index_submissions_on_requires_review_and_requests_review"
    add_index :submissions, [:course_id, :requires_review, :requests_review], name: "index_submissions_on_course_id_and_reviews"
  end
end
