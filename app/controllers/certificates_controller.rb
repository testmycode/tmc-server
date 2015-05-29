class CertificatesController < ApplicationController

  add_breadcrumb 'Participants', :participants_path, only: [:new, :create], if: -> { current_user.administrator? }

  def show
    certificate = Certificate.find params[:id]
    authorize! :read, certificate

    visible_exercises = certificate.course.exercises.select { |e| e.points_visible_to?(certificate.user) }
    total_available = AvailablePoint.course_points_of_exercises(certificate.course, visible_exercises).length
    points = AwardedPoint.course_user_points(certificate.course, certificate.user).length

    cert_path = File.join(certificate.course.clone_path, 'certificate')

    data = File.read(File.join(cert_path, 'certificate.html'))
    data %= {
      name: certificate.name,
      course: certificate.course.formal_name,
      weeks: certificate.course.exercise_groups.length,
      exercises: visible_exercises.length,
      points: points,
      total_available: total_available,
      root: cert_path
    }

    kit = PDFKit.new(data, {
      disable_local_file_access: true,
      allow: {"#{cert_path}" => true},
      page_size: 'A4',
      orientation: 'Landscape',
      margin_top: '0.20in',
      margin_right: '0.20in',
      margin_bottom: '0.20in',
      margin_left: '0.20in'
    })

    stylesheet = File.join(cert_path, 'style.css')
    kit.stylesheets << stylesheet if File.exists? stylesheet

    send_data kit.to_pdf, type: :pdf , disposition: 'inline'
  end

  def new
    @user = User.find params[:participant_id]
    authorize! :read, @user
    @course = Course.find params[:course_id]
    authorize! :read, @course

    @certificate = Certificate.new(user: @user, course: @course)
    authorize! :create, @certificate

    if current_user.administrator?
      add_breadcrumb @user.username, participant_path(@user)
    else
      add_breadcrumb 'My stats', participant_path(@user)
    end
    add_breadcrumb "Course #{@course.name}", course_path(@course)
    add_breadcrumb 'Certificate'
  end

  def create
    @certificate = Certificate.new certificate_params
    @user = @certificate.user
    @course = @certificate.course
    authorize! :read, @user
    authorize! :read, @course
    authorize! :create, @certificate

    if @certificate.save
      redirect_to @certificate
    else
      render action: :new
    end
  end

  private
  def certificate_params
    params.require(:certificate).permit(:name, :user_id, :course_id)
  end
end
