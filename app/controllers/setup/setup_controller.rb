class Setup::SetupController < ApplicationController
  before_action :set_organization, :add_setup_breadcrumb

  STEPS =
    [
      {
        # step_number: 1,
        title: 'Template',
        path: :setup_organization_course_chooser_index_path
      },
      {
        # step_number: 2,
        title: 'Details',
        path: :edit_setup_organization_course_course_details_path
      },
      {
        # step_number: 3,
        title: 'Timing',
        path: :setup_organization_course_course_timing_path
      },
      {
        # step_number: 4,
        title: 'Assistants',
        path: :setup_organization_course_course_assistants_path
      },
      {
        # step_number: 5,
        title: 'Finish',
        path: :setup_organization_course_course_finisher_index_path
      }
    ].freeze

  def step_number(title)
    found = 0
    STEPS.each do |st|
      found += 1
      return found if st[:title] == title
    end
    nil
  end

  def link_to_next_step(step_number)
    STEPS[step_number][:path]
  end

  def add_setup_breadcrumb
    add_breadcrumb 'Setup', setup_start_index_path
    add_breadcrumb 'Create new course' if controller_name.starts_with?('course_') && setup_in_progress?
  end

  def print_setup_phases(phase = 0)
    update_setup_phase(phase) unless phase == 2
    maxphase = setup_in_progress? ? session[:ongoing_course_setup][:phase] : phase
    STEPS.each_with_index do |st, i|
      path = nil
      if i == phase - 1
        type = 'current'
      elsif i < maxphase
        type = 'visited'
        path = st[:path]
      else
        type = 'unavailable'
      end
      options = {}
      options = { pass_parameters: true } if setup_in_progress? && course_choosed?
      add_phase (i+1).to_s+'. '+STEPS[i][:title], type, path, options
    end
  end

  def add_phase(name, type, url = '', options = {})
    @course_setup_phases ||= []
    if options[:pass_parameters]
      url = url.to_s + "('#{@organization.slug}', #{@course.id})"
    end
    url = eval(url.to_s) if url =~ /_path|_url|@/
    @course_setup_phases << { name: name, url: url, type: type }
  end

  private

  def save_wizard_to_session(phase = 1)
    return if setup_in_progress?
    session[:ongoing_course_setup] = {
        course_id: nil,
        phase: phase,
        started: Time.now
    }
  end

  def setup_in_progress?
    return false if session[:ongoing_course_setup].nil?
    if !session[:ongoing_course_setup][:course_id].nil? && !@course.nil?
      session[:ongoing_course_setup][:course_id] == @course.id
    else
      true
    end
  end

  def course_choosed?
    return false if session[:ongoing_course_setup].nil?
    !session[:ongoing_course_setup][:course_id].nil?
  end

  def reset_setup_session
    session[:ongoing_course_setup] = nil
  end

  def update_setup_phase(phase)
    if setup_in_progress?
      session[:ongoing_course_setup][:phase] = phase if session[:ongoing_course_setup][:phase] < phase
    end
  end

  def update_setup_course(id = nil)
    return unless setup_in_progress?
    if id.nil?
      session[:ongoing_course_setup][:course_id] = @course.id
    else
      session[:ongoing_course_setup][:course_id] = id
    end
  end

  def set_organization
    @organization = Organization.find_by(slug: params[:organization_id])
  end

  def set_course
    @course = Course.find(params[:course_id]) unless params[:course_id].nil?
  end
end
