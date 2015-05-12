class CertificatesController < ApplicationController

  def index
    @user = User.find(params[:participant_id])
    authorize! :read, @user
    @names = @user.certificates.order(:name).distinct.pluck(:name)
  end

  def show
    certificate = Certificate.find params[:id]
    authorize! :read, certificate

    visible_exercises = certificate.course.exercises.select { |e| e.points_visible_to?(certificate.user) }
    total_available = AvailablePoint.course_points_of_exercises(certificate.course, visible_exercises).count
    points = AwardedPoint.course_user_points(certificate.course, certificate.user).count

    cert_path = File.join(certificate.course.clone_path, 'certificate')

    data = File.read(File.join(cert_path, 'certificate.html'))
    data %= {
      name: certificate.name,
      course: certificate.course.formal_name,
      weeks: certificate.course.exercise_groups.count,
      exercises: visible_exercises.count,
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

    send_data kit.to_pdf, type: :pdf , disposition: 'inline'
  end

  def new
    @user =
      if params[:participant_id]
        User.find params[:participant_id]
      else
        current_user
      end
    authorize! :read, @user

    return respond_access_denied('Authentication required') if @user.guest?

    @certificate = Certificate.new(user: @user)

    @courses = courses
    return redirect_to :back, alert: 'No courses' if @courses.empty?
    add_certificate_breadcrumbs
  end

  def create
    @certificate = Certificate.new certificate_params
    authorize! :read, @certificate.user
    authorize! :read, @certificate.course
    authorize! :create, @certificate

    if @certificate.save
      redirect_to @certificate
    else
      @courses = courses
      add_certificate_breadcrumbs
      render action: :new
    end
  end

  private
  def certificate_params
    params.require(:certificate).permit(:name, :user_id, :course_id)
  end

  def courses
    @courses ||= Course
      .order(:name)
      .select { |c| c.visible_to?(@certificate.user) and c.certificate_downloadable_for? (@certificate.user) }
  end

  def add_certificate_breadcrumbs
    unless @certificate.user == current_user
      add_breadcrumb 'Participants', :participants_path
      add_breadcrumb @certificate.user.display_name, participant_path(@certificate.user)
    end
    add_breadcrumb 'Certificate'
  end
end
