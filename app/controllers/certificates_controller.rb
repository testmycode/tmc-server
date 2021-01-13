# frozen_string_literal: true

class CertificatesController < ApplicationController
  before_action :set_user, except: [:show]
  before_action :set_courses, except: [:show]
  before_action :add_certificate_breadcrumbs, except: [:show]

  def index
    authorize! :read, @user
    @certificates = @user.certificates.order(:created_at).includes(:course)
    @names = @certificates.map(&:name).uniq.sort

    @certificate = Certificate.new(user: @user)

    last_certificate =  @certificates.last
    @certificate.name = last_certificate.name if last_certificate
  end

  def show
    certificate = Certificate.find params[:id]
    authorize! :read, certificate

    send_data certificate.pdf, type: :pdf, disposition: 'inline'
  end

  def create
    @certificate = Certificate.new certificate_params
    authorize! :read, @certificate.user
    authorize! :read, @certificate.course
    authorize! :create, @certificate

    if @certificate.save
      redirect_to participant_certificates_path(@user), notice: "Certificate successfully created. <a href=\"#{certificate_path(@certificate)}\">View certificate</a>"
    else
      render action: :new
    end
  rescue Errno::ENOENT
    redirect_to participant_certificates_path(@user), alert: 'Cannot create certificate for this course.'
  end

  private
    def certificate_params
      params.require(:certificate).permit(:name, :user_id, :course_id)
    end

    def set_user
      id = params[:participant_id] || params[:certificate][:user_id]
      @user = User.find(id)
    end

    def set_courses
      @courses = current_user.administrator? ? Course.where(certificate_downloadable: true).order(:name) : Course.with_certificates_for(@user)
    end

    def add_certificate_breadcrumbs
      if @user == current_user
        add_breadcrumb 'My stats', participant_path(@user)
      elsif current_user.administrator?
        add_breadcrumb 'Participants', :participants_path
        add_breadcrumb @user.display_name, participant_path(@user)
      end
      add_breadcrumb 'Certificate'
    end
end
