# Displays the raw list of participant e-mails, useful for mass-mailing scripts.
class EmailsController < ApplicationController
  def index
    organization_id = params[:organization_id]
    course_id = params[:id]

    if organization_id && course_id
      index_course
    else
      index_global
    end
  end

  private

  def index_global
    authorize! :view, :emails
    filter_params = params_starting_with('filter_', :all, remove_prefix: true)
    filter_params['include_administrators'] = '1' # Always include administrators. Could make this exclude_administrators instead
    @emails = User.filter_by(filter_params).order(:email).map(&:email)
    respond_to do |format|
      format.text do
        render text: @emails.join("\n")
      end
    end
  end

  def index_course
    @course = Course.find(params[:id])
    @organization = @course.organization

    authorize! :list_user_emails, @course

    add_course_breadcrumb
    add_breadcrumb('Students', organization_emails_path)

    @students = User.course_students(@course)

    respond_to do |format|
      format.html
      format.text { render text: @students.map { |s| "#{s.email}" }.join("\n") }
      format.csv { render text: "Username,Email\n" + @students.map { |s| "#{s.username},#{s.email}" }.join("\n") }
    end
  end
end
