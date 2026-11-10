# typed: strict
# frozen_string_literal: true

class CertificatesController < ApplicationController
  extend T::Sig
  before_action :set_user, except: [:show]
  before_action :set_courses, except: [:show]
  before_action :add_certificate_breadcrumbs, except: [:show]

  sig { void }
  def index
    authorize! :read, @user
    certificates = T.must(@user).certificates.order(:created_at).includes(:course)
    @certificates = T.let(certificates, T.nilable(ActiveRecord::Relation))
    @names = T.let(certificates.map(&:name).uniq.sort, T.nilable(T::Array[T.nilable(String)]))

    certificate = Certificate.new(user: @user)
    @certificate = T.let(certificate, T.nilable(Certificate))

    last_certificate = certificates.last
    certificate.name = last_certificate.name if last_certificate
  end

  sig { void }
  def show
    certificate = Certificate.find params[:id]
    authorize! :read, certificate

    send_data certificate.pdf, type: :pdf, disposition: 'inline'
  end

  sig { void }
  def create
    @certificate = Certificate.new certificate_params
    authorize! :read, @certificate.user
    authorize! :read, @certificate.course
    authorize! :create, @certificate

    if @certificate.save
      redirect_to participant_certificates_path(@user), notice: helpers.safe_join(['Certificate successfully created. ', helpers.link_to('View certificate', certificate_path(@certificate))])
    else
      render action: :new
    end
  rescue Errno::ENOENT
    redirect_to participant_certificates_path(@user), alert: 'Cannot create certificate for this course.'
  end

  private
    sig { returns(ActionController::Parameters) }
    def certificate_params
      params.require(:certificate).permit(:name, :user_id, :course_id)
    end

    sig { void }
    def set_user
      id = params[:participant_id] || params[:certificate][:user_id]
      @user = T.let(User.find(id), T.nilable(User))
    end

    sig { void }
    def set_courses
      courses = current_user.administrator? ? Course.where(certificate_downloadable: true).order(:name) : Course.with_certificates_for(@user)
      @courses = T.let(courses, T.nilable(T::Enumerable[Course]))
    end

    sig { void }
    def add_certificate_breadcrumbs
      user = T.must(@user)
      if user == current_user
        add_breadcrumb 'My stats', participant_path(user)
      elsif current_user.administrator?
        add_breadcrumb 'Participants', :participants_path
        add_breadcrumb user.display_name, participant_path(user)
      end
      add_breadcrumb 'Certificate'
    end
end
