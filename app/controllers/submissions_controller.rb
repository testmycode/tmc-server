require 'submission_processor'

# Receives submissions and presents the full submission list and submission view.
# Also handles rerun requests.
class SubmissionsController < ApplicationController
  around_action :course_transaction

  # Manually checked for #show and index
  skip_authorization_check only: [:show, :index]

  def index
    set_course

    respond_to do |format|
      format.json do
        if params[:row_format] == 'datatables'
          index_json_datatables
        else
          index_json
        end
      end
      format.html do # uses AJAX
        add_course_breadcrumb
        add_breadcrumb 'All submissions', organization_course_submissions_path(@organization, @course)
      end
    end
  end

  def show
    if params[:paste_key]
      return unless set_paste
    else
      set_submission
    end

    @files = SourceFileList.for_submission(@submission)
    add_course_breadcrumb
    add_exercise_breadcrumb
    add_submission_breadcrumb

    respond_to do |format|
      format.html
      format.zip { send_data(@submission.return_file, filename: "#{@submission.user.login}-#{@exercise.name}-#{@submission.id}.zip") }
      format.json do
        output = {
          api_version: ApiVersion::API_VERSION,
          all_tests_passed: @submission.all_tests_passed?,
          user_id: @submission.user_id,
          course: @course.name,
          exercise_name: @submission.exercise.name,
          status: @submission.status,
          points: @submission.points_list,
          processing_time: @submission.processing_time,
          message_for_paste: @submission.message_for_paste,
          missing_review_points: @exercise.missing_review_points_for(@submission.user)
        }
        output = output.merge(
          case @submission.status
          when :processing then {
            submissions_before_this: @submission.unprocessed_submissions_before_this,
            total_unprocessed: Submission.unprocessed_count
          }
          when :error then { error: @submission.pretest_error }
          when :fail then {
            test_cases: @submission.test_case_records
          }
          when :ok then {
            test_cases: @submission.test_case_records,
            feedback_questions: @course.feedback_questions.order(:position).map(&:record_for_api),
            feedback_answer_url: submission_feedback_answers_url(@submission, format: :json),
            processing_time: @submission.processing_time
          }
          end
        )

        if @exercise.solution.visible_to?(current_user)
          output[:solution_url] = view_context.organization_course_exercise_solution_url(@organization, @course, @exercise)
        end

        output[:validations] = @submission.validations
        output[:valgrind] = @submission.valgrind

        if @submission.paste_available?
          output[:paste_url] = paste_url(@submission.paste_key)
          output[:message_for_paste] = @submission.message_for_paste
        end

        output[:reviewed] = @submission.reviewed?
        output[:requests_review] = @submission.requests_review?
        output[:submitted_at] = @submission.created_at

        render json: output
      end
    end
  end

  def create
    set_exercise

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
          redirect_to(organization_course_exercise_path(@organization, @course, @exercise),
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
    set_submission

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
    set_exercise(:id)

    for submission in @exercise.submissions
      schedule_for_rerun(submission, -2)
    end
    redirect_to organization_course_exercise_path(@organization, @course, @exercise), notice: 'Reruns scheduled'
  end

  private

  def course_transaction
    Course.transaction(requires_new: true) do
      yield
    end
  end

  def set_submission
    @submission = Submission.find(params[:id])
    @exercise = @submission.exercise
    @course = @submission.course
    @organization = @course.organization
    authorize! :read, @submission
  end

  def set_exercise(param_name = :exercise_id)
    @course = Course.lock('FOR SHARE').find_by(name: params[:course_id])
    @exercise = Exercise.find_by(name: params[param_name], course: @course)
    @organization = Organization.find_by(slug: params[:organization_id])
    check_course_matches_organization
    check_exercise_matches_course
    authorize! :read, @course
    authorize! :read, @exercise
  end

  def set_course
    @course = Course.lock('FOR SHARE').find_by(name: params[:course_id])
    @organization = @course.organization
    check_course_matches_organization
    authorize! :read, @course
  end

  def set_paste
    @submission = Submission.find_by_paste_key!(params[:paste_key])
    @exercise = @submission.exercise
    @course = @submission.course
    @organization = @course.organization
    @is_paste = true
    check_access!
  end

  def check_course_matches_organization
    fail ActiveRecord::RecordNotFound unless @course && @course.organization == @organization
  end

  def check_exercise_matches_course
    fail ActiveRecord::RecordNotFound unless @exercise && @exercise.course == @course
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
    can_access = true
    case paste_visibility
    when 'protected'
      can_access = false unless can?(:teach, @course) || @submission.user_id.to_s == current_user.id.to_s || (@submission.public? && @submission.exercise.completed_by?(current_user))
    when 'no-tests-public'
      can_access = false unless @submission.created_at > 2.hours.ago
    else
      can_access = false unless can?(:teach, @course) || @submission.user_id.to_s == current_user.id.to_s || (@submission.public? && @submission.created_at > 2.hours.ago)
    end
    respond_access_denied unless can_access
    can_access
  end
end
