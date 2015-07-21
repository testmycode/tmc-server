require 'submission_processor'

# Receives submissions and presents the full submission list and submission view.
# Also handles rerun requests.
class SubmissionsController < ApplicationController
  around_action :course_transaction
  before_action :get_course_and_exercise

  # Manually checked for #show and index
  skip_authorization_check only: [:show, :index]

  def index
    respond_to do |format|
      format.json do
        if params[:row_format] == 'datatables'
          index_json_datatables
        else
          index_json
        end
      end
      format.html do # uses AJAX
        @organization = @course.organization
        add_course_breadcrumb
        add_breadcrumb 'All submissions'
      end
    end
  end

  def show
    @course ||= @submission.course
    @exercise ||= @submission.exercise
    @organization = @course.organization
    add_course_breadcrumb
    add_exercise_breadcrumb
    add_submission_breadcrumb

    respond_to do |format|
      format.html {
        @files = SourceFileList.for_submission(@submission)
      }
      format.zip {
        send_data(@submission.return_file, filename: "#{@submission.user.login}-#{@exercise.name}-#{@submission.id}.zip")
      }
      format.json do
        output = {
          api_version: ApiVersion::API_VERSION,
          all_tests_passed: @submission.all_tests_passed?,
          user_id: @submission.user_id,
          course: @course.name,
          exercise_name: @submission.exercise.name,
          status: @submission.status(current_user),
          points: @submission.points_list,
          validations: @submission.validations,
          valgrind: @submission.valgrind,
          solution_url: @exercise.solution.visible_to?(current_user) ? view_context.exercise_solution_url(@exercise) : nil,
          submitted_at: @submission.created_at,
          processing_time: @submission.processing_time,
          reviewed: @submission.reviewed?,
          requests_review:  @submission.requests_review?,
          paste_url: @submission.paste_available ? paste_url(@submission.paste_key) : nil,
          message_for_paste: @submission.paste_available ? @submission.message_for_paste : nil,
          missing_review_points: @exercise.missing_review_points_for(@submission.user)
        }

        output = output.merge(
          case @submission.status(current_user)
            when :processing then {
              submissions_before_this: @submission.unprocessed_submissions_before_this,
              total_unprocessed: Submission.unprocessed_count
            }
            when :ok then {
              test_cases: @submission.test_case_records,
              feedback_questions: @course.feedback_questions.order(:position).map(&:record_for_api),
              feedback_answer_url: submission_feedback_answers_url(@submission, format: :json),
            }
            when :fail then {
              test_cases: @submission.test_case_records
            }
            when :hidden then {
              all_tests_passed:  nil,
              test_cases: nil,
              points: nil,
              validations: nil,
              valgrind: nil
            }
            when :error then {
              error: @submission.pretest_error
            }
          end
        )

        render json: output
      end
    end
  end

  def create
    if !params[:submission] || !params[:submission][:file]
      return respond_not_found('No ZIP file selected or failed to receive it')
    end

    unless @exercise.submittable_by?(current_user)
      return respond_access_denied('Submissions for this exercise are no longer accepted.')
    end

    file_contents = File.read(params[:submission][:file].tempfile.path)

    errormsg = nil

    unless file_contents.start_with?('PK')
      errormsg = "The uploaded file doesn't look like a ZIP file."
    end

    submission_params = {
      error_msg_locale: params[:error_msg_locale]
    }

    unless errormsg
      @submission = Submission.new(
        user: current_user,
        course: @course,
        exercise: @exercise,
        return_file: file_contents,
        params_json: submission_params.to_json,
        requests_review: !!params[:request_review],
        paste_available: !!params[:paste],
        message_for_paste: if params[:paste] then params[:message_for_paste] || '' else '' end,
        message_for_reviewer: if params[:request_review] then params[:message_for_reviewer] || '' else '' end,
        client_time: if params[:client_time] then Time.at(params[:client_time].to_i) else nil end,
        client_nanotime: params[:client_nanotime],
        client_ip: request.env['HTTP_X_FORWARDED_FOR'] || request.remote_ip
      )

      authorize! :create, @submission

      unless @submission.save
        errormsg = 'Failed to save submission.'
      end
    end

    unless errormsg
      SubmissionProcessor.new.process_submission(@submission)
    end

    respond_to do |format|
      format.html do
        if !errormsg
          redirect_to(submission_path(@submission),
                      notice: 'Submission received.')
        else
          redirect_to(exercise_path(@exercise),
                      alert: errormsg)
        end
      end
      format.json do
        if !errormsg
          render json: { submission_url: submission_url(@submission, format: 'json', api_version: ApiVersion::API_VERSION),
                         paste_url: if @submission.paste_key then paste_url(@submission.paste_key) else '' end }
        else
          render json: { error: errormsg }
        end
      end
    end
  end

  def update
    submission = Submission.find(params[:id]) || respond_not_found
    authorize! :update, submission
    if params[:rerun]
      schedule_for_rerun(submission, -1)
      redirect_to submission_path(submission), notice: 'Rerun scheduled'
    elsif params[:dismiss_review]
      submission.review_dismissed = true
      submission.save!
      redirect_to new_submission_review_path(submission), notice: 'Code review dismissed'
    else
      respond_not_found
    end
  end

  def update_by_exercise
    for submission in @exercise.submissions
      schedule_for_rerun(submission, -2)
    end
    redirect_to exercise_path(@exercise), notice: 'Reruns scheduled'
  end

  private

  def course_transaction
    Course.transaction(requires_new: true) do
      yield
    end
  end

  # Ugly manual access control :/
  def get_course_and_exercise
    if params[:id]
      @submission = Submission.find(params[:id])
      authorize! :read, @submission
      @course = @submission.course
      @exercise = @submission.exercise
    elsif params[:exercise_id]
      @exercise = Exercise.find(params[:exercise_id])
      @course = Course.lock('FOR SHARE').find(@exercise.course_id)
      authorize! :read, @course
      authorize! :read, @exercise
    elsif params[:paste_key]
      @submission = Submission.find_by_paste_key!(params[:paste_key])
      @exercise = @submission.exercise
      @course = @exercise.course
      @is_paste = true
      check_access!
    elsif params[:course_id]
      @course = Course.lock('FOR SHARE').find(params[:course_id])
      authorize! :read, @course
    else
      respond_access_denied
    end
  end

  def schedule_for_rerun(submission, priority)
    submission.set_to_be_reprocessed!(priority)
  end

  def index_json
    return respond_access_denied unless current_user.administrator?

    submissions = @course.submissions
    if params[:user_id]
      submissions = submissions.where(user_id: params[:user_id])
    end

    render json: {
      api_version: ApiVersion::API_VERSION,
      json_url_schema: submission_url(id: ':id', format: 'json'),
      zip_url_schema: submission_url(id: ':id', format: 'zip'),
      submissions: submissions.map(&:id)
    }
  end

  def index_json_datatables
    submissions = @course.submissions

    unless current_user.administrator?
      submissions = submissions.where(user_id: current_user.id)
    end

    if params[:max_id]
      submissions = submissions.where('id <= ?', params[:max_id])
    end
    submissions = submissions.includes(:user).order('id DESC')
    remaining = submissions.count
    submissions_limited = submissions.limit(1000)
    Submission.eager_load_exercises(submissions_limited)

    render json: {
      remaining: remaining,
      max_id: params[:max_id].to_i,
      last_id: if submissions_limited.empty? then nil else submissions_limited.last.id.to_i end,
      rows: view_context.submissions_for_datatables(submissions_limited)
    }
  end

  def check_access!
    paste_visibility = @course.paste_visibility || 'open'
    case paste_visibility
    when 'protected'
      respond_access_denied unless current_user.administrator? || @submission.user_id.to_s == current_user.id.to_s || (@submission.public? && @submission.exercise.completed_by?(current_user))
    when 'no-tests-public'
      respond_access_denied unless @submission.created_at > 2.hours.ago
    else
      respond_access_denied unless current_user.administrator? || @submission.user_id.to_s == current_user.id.to_s || (@submission.public? && @submission.created_at > 2.hours.ago)
    end
  end
end
