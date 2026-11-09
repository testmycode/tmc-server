# typed: strict
# frozen_string_literal: true

require 'csv'

# Displays the raw list of participant e-mails, useful for mass-mailing scripts.
class EmailsController < ApplicationController
  extend T::Sig
  sig { void }
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
    sig { void }
    def index_global
      authorize! :view, :emails
      filter_params = params_starting_with('filter_', :all, remove_prefix: true)
      filter_params['include_administrators'] = '1' # Always include administrators. Could make this exclude_administrators instead
      emails = User.filter_by(filter_params).order(:email).map(&:email)
      @emails = T.let(emails, T.nilable(T::Array[String]))
      respond_to do |format|
        format.text do
          render plain: emails.join("\n")
        end
      end
    end

    sig { void }
    def index_course
      @course = Course.find(params[:id])
      @organization = @course.organization

      authorize! :list_user_emails, @course

      add_course_breadcrumb
      add_breadcrumb('Students', organization_emails_path)

      students = User.course_students(@course)
      @students = T.let(students, T.nilable(ActiveRecord::Relation))

      respond_to do |format|
        format.html
        format.text { render plain: students.map { |s| s.email.to_s }.join("\n") }
        format.csv do
          csv = CSV.generate do |rows|
            rows << %w[Username Email]
            students.each { |s| rows << [s.username, s.email].map { |cell| CsvCell.escape(cell) } }
          end
          render plain: csv
        end
      end
    end
end
