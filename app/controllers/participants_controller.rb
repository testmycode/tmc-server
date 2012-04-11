class ParticipantsController < ApplicationController
  skip_authorization_check
  before_filter :require_administrator

  def index
    @filter_params = params_starting_with('filter_', :remove_prefix => true)
    @raw_filter_params = params_starting_with('filter_', :remove_prefix => false)
    @participants = User.filter_by(@filter_params).order(:login)

    @extra_fields = UserField.all.select(&:show_in_participant_list?)

    respond_to do |format|
      format.html
      format.json do
        result = []
        @participants.each do |user|
          record = { :id => user.id, :username => user.login, :email => user.email }
          @extra_fields.each do |field|
            record[field.name] = user.field_value(field)
          end
          result << record
        end
        render :json => {
          :api_version => API_VERSION,
          :participants => result
        }
      end
    end
  end

  def show
    @user = User.find(params[:id])
    @awarded_points = Hash[@user.awarded_points.to_a.sort!.group_by(&:course_id).map {|k, v| [k, v.map(&:name)]}]

    @courses = []
    @missing_points = {}
    @percent_completed = {}
    for course_id in @awarded_points.keys
      course = Course.find(course_id)
      @courses << course

      awarded = @awarded_points[course.id]
      missing = AvailablePoint.course_points(course).sort!.map(&:name) - awarded
      @missing_points[course_id] = missing

      if awarded.size + missing.size > 0
        @percent_completed[course_id] = 100 * (awarded.size.to_f / (awarded.size + missing.size))
      else
        @percent_completed[course_id] = 0
      end
    end
  end
  
  def destroy
    user = User.find(params[:id])
    user.destroy
    flash[:success] = 'User account deleted'
    redirect_to root_path
  end

private
  def require_administrator
    respond_access_denied unless current_user.administrator? || params[:id] == current_user.id.to_s
  end
end
