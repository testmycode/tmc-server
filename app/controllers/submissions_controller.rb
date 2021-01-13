# frozen_string_literal: true

require 'submission_processor'

# Receives submissions and presents the full submission list and submission view.
# Also handles rerun requests.
class SubmissionsController < ApplicationController
  around_action :course_transaction
  before_action :get_course_and_exercise

  # Manually checked for #show and index
  skip_authorization_check only: %i[show index difference_with_solution]

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
        respond_forbidden if !current_user.administrator? && @course.hide_submissions?
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

    @model_solution_token_used = ModelSolutionTokenUsed.where(course: @course, exercise_name: @exercise.name, user: @submission.user)

    add_course_breadcrumb
    add_exercise_breadcrumb
    add_submission_breadcrumb

    respond_to do |format|
      format.html do
        respond_forbidden if !current_user.administrator? && @course.hide_submissions?
        @files = SourceFileList.for_submission(@submission)
      end
      format.zip do
        respond_forbidden if !current_user.administrator? && @course.hide_submissions?
        send_data(@submission.return_file, filename: "#{@submission.user.login}-#{@exercise.name}-#{@submission.id}.zip")
      end
      format.json do
        output = {
          api_version: ApiVersion::API_VERSION,
          all_tests_passed: @submission.all_tests_passed?,
          user_id: @submission.user_id,
          login: @submission.user.login,
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
            feedback_answer_url: submission_feedback_answers_url(@submission, format: :json)
          }
          when :fail then {
            test_cases: @submission.test_case_records
          }
          when :hidden then {
            all_tests_passed:  nil,
            test_cases: [{ name: 'TestResultsAreHidden test', successful: true, message: nil, exception: nil, detailed_message: nil }],
            points: [],
            validations: nil,
            valgrind: nil
          }
          when :error then {
            error: @submission.pretest_error
          }
          end
        )
        output[:status] = :ok if output[:status] == :hidden
        if !!params[:include_files]
          output[:files] = SourceFileList.for_submission(@submission).map { |f| { path: f.path, contents: f.contents } }
        end

        render json: output
      end
    end
  end

  def create
    if !params[:submission] || !params[:submission][:file]
      return respond_not_found('No ZIP file selected or failed to receive it')
    end

    unless @exercise.submittable_by?(current_user)
      return respond_forbidden('Submissions for this exercise are no longer accepted.')
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
        message_for_paste: params[:paste] ? (params[:message_for_paste] || '') : '',
        message_for_reviewer: params[:request_review] ? (params[:message_for_reviewer] || '') : '',
        client_time: params[:client_time] ? Time.at(params[:client_time].to_i) : nil,
        client_nanotime: params[:client_nanotime],
        client_ip: request.env['HTTP_X_FORWARDED_FOR'] || request.remote_ip
      )

      authorize! :create, @submission

      errormsg = 'Failed to save submission.' unless @submission.save
    end

    unless errormsg
      # SubmissionProcessor.new.process_submission(@submission)
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
                         paste_url: @submission.paste_key ? paste_url(@submission.paste_key) : '' }
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
      authorize! :rerun, submission
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

  def difference_with_solution
    @course ||= @submission.course
    authorize! :teach, @course
    @exercise ||= @submission.exercise
    @organization = @course.organization
    add_course_breadcrumb
    add_exercise_breadcrumb
    add_submission_breadcrumb
    add_breadcrumb 'Difference with model solution'

    submission_files = SourceFileList.for_submission(@submission)
    solution_files = SourceFileList.for_solution(@exercise.solution)
    files_in_list = Set.new
    @files = []
    submission_files.each do |file|
      # TODO: In some exercises files may be named differently. Some kind of
      # similarity metric would be nice here
      model = solution_files.find { |solution_file| file.path == solution_file.path }
      @files << {
        path: file.path,
        submission_contents: file.contents,
        model_contents: (model.nil? ? '' : model.contents)
      }
      files_in_list << file.path
    end
    solution_files.each do |file|
      next if files_in_list.include?(file.path)
      @files << {
        path: file.path,
        submission_contents: '',
        model_contents: file.contents
      }
    end
  end

  private
    def course_transaction
      Course.transaction(requires_new: true) do
        yield
      end
    end

    # Ugly manual access control :/
    def get_course_and_exercise
      submission_id = params[:id] || params[:submission_id]
      if submission_id
        @submission = Submission.find(submission_id)
        authorize! :read, @submission
        @course = @submission.course
        @exercise = @submission.exercise
      elsif params[:exercise_id]
        @exercise = Exercise.find(params[:exercise_id])
        @course = Course.lock('FOR SHARE').find(@exercise.course_id)
        authorize! :read, @course
        authorize! :read, @exercise
      elsif params[:paste_key]
        @submission = Submission.find_by!(paste_key: params[:paste_key])
        @exercise = @submission.exercise
        @course = @exercise.course
        @is_paste = true
        check_access!
      elsif params[:course_id]
        @course = Course.lock('FOR SHARE').find(params[:course_id])
        @organization = @course.organization
        authorize! :read, @course
      else
        respond_forbidden
      end
    end

    def schedule_for_rerun(submission, priority)
      submission.set_to_be_reprocessed!(priority)
    end

    def index_json
      return respond_forbidden unless current_user.administrator?

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

      unless current_user.administrator? || can?(:teach, @course)
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
        last_id: submissions_limited.empty? ? nil : submissions_limited.last.id.to_i,
        rows: view_context.submissions_for_datatables(submissions_limited)
      }
    end

    def check_access!
      if current_user.guest?
        raise CanCan::AccessDenied
      end

      paste_visible = @submission.paste_visible_for?(current_user)
      return if paste_visible
      paste_visibility = @exercise.paste_visibility
      paste_visibility ||= @course.paste_visibility
      paste_visibility ||= 'open'
      case paste_visibility
      when 'protected', 'secured'
        respond_forbidden unless can?(:teach, @course) || @submission.user_id.to_s == current_user.id.to_s || paste_visible
      when 'no-tests-public'
        respond_forbidden unless can?(:teach, @course) || @submission.created_at > 2.hours.ago || @submission.user_id.to_s == current_user.id.to_s
      when 'everyone'
        nil
      else
        return if can?(:teach, @course) || @submission.user_id.to_s == current_user.id.to_s
        if @submission.created_at > 2.hours.ago
          respond_forbidden("You cannot see this paste because all tests passed and you haven't completed this exercise.") unless paste_visible
          return
        else
          unless paste_visible
            if @submission.exercise && !@submission.exercise.completed_by?(current_user)
              respond_forbidden("You cannot see this paste because you haven't completed this exercise.")
              return
            else
              respond_forbidden('You cannot see this paste because it was created over 2 hours ago.')
            end
            return
          end
        end

        respond_forbidden('You cannot see this paste because all tests passed.') unless paste_visible
      end
    end
end
