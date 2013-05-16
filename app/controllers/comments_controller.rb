class CommentsController < ApplicationController
  skip_authorization_check
  def index
    @submission = Submission.find(params[:submission_id])
    @comments = @submission.comments

    respond_to do |format|
      format.json { render json: @comments.collect { |comment| comment.to_my_json } }
    end
  end

  def show
    @comment = Comment.find(params[:id])

    respond_to do |format|
      format.json { render json: @comment.to_my_json }
    end
  end

  def create
    @comment = Comment.new()
    @comment.comment = params[:comment]
    @comment.user = current_user
    @comment.submission = Submission.find(params[:submission_id])
    respond_to do |format|
      if @comment.save
        format.json { render json: @comment, status: :created, location: @comment }
      else
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end
end
