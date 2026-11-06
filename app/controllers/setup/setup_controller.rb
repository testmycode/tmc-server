# typed: strict
# frozen_string_literal: true

class Setup::SetupController < ApplicationController
  extend T::Sig
  before_action :set_organization, :add_setup_breadcrumb

  STEPS = T.let(
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
      # Deprecated since tmc-langs-rust refresh implementation
      # {
      #   # step_number: 3,
      #   title: 'Timing',
      #   path: :setup_organization_course_course_timing_path
      # },
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
    ].freeze,
    T::Array[{ title: String, path: Symbol }]
  )

  sig { params(title: String).returns(T.nilable(Integer)) }
  def step_number(title)
    found = 0
    STEPS.each do |st|
      found += 1
      return found if st[:title] == title
    end
    nil
  end

  sig { params(step_number: Integer).returns(Symbol) }
  def link_to_next_step(step_number)
    STEPS.fetch(step_number)[:path]
  end

  sig { void }
  def add_setup_breadcrumb
    add_breadcrumb 'Setup', setup_start_index_path
    add_breadcrumb 'Create new course' if controller_name.starts_with?('course_') && setup_in_progress?
  end

  sig { params(phase: Integer).void }
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
      add_phase (i + 1).to_s + '. ' + st[:title], type, path, options
    end
  end

  # url: a route helper name, evaluated here with the current organization and course when
  # options[:pass_parameters] is set.
  sig { params(name: String, type: String, url: T.nilable(T.any(String, Symbol)), options: T::Hash[Symbol, T.untyped]).void }
  def add_phase(name, type, url = '', options = {})
    phases = @course_setup_phases ||= T.let([], T.nilable(T::Array[T::Hash[Symbol, T.untyped]]))
    if options[:pass_parameters]
      url = url.to_s + "('#{T.must(@organization).slug}', #{T.must(@course).id})"
    end
    url = eval(url.to_s) if url =~ /_path|_url|@/
    phases << { name: name, url: url, type: type }
  end

  private
    sig { params(phase: Integer).void }
    def save_wizard_to_session(phase = 1)
      return if setup_in_progress?
      session[:ongoing_course_setup] = {
        course_id: nil,
        phase: phase,
        started: Time.now
      }
    end

    sig { returns(T::Boolean) }
    def setup_in_progress?
      return false if session[:ongoing_course_setup].nil?
      if !session[:ongoing_course_setup][:course_id].nil? && !@course.nil?
        session[:ongoing_course_setup][:course_id] == @course.id
      else
        true
      end
    end

    sig { returns(T::Boolean) }
    def course_choosed?
      return false if session[:ongoing_course_setup].nil?
      !session[:ongoing_course_setup][:course_id].nil?
    end

    sig { void }
    def reset_setup_session
      session[:ongoing_course_setup] = nil
    end

    sig { params(phase: Integer).void }
    def update_setup_phase(phase)
      if setup_in_progress?
        session[:ongoing_course_setup][:phase] = phase if session[:ongoing_course_setup][:phase] < phase
      end
    end

    sig { params(id: T.nilable(Integer)).void }
    def update_setup_course(id = nil)
      return unless setup_in_progress?
      session[:ongoing_course_setup][:course_id] = if id.nil?
        T.must(@course).id
      else
        id
      end
    end

    sig { void }
    def set_organization
      @organization = Organization.find_by(slug: params[:organization_id])
    end

    sig { void }
    def set_course
      @course = Course.find(params[:course_id]) unless params[:course_id].nil?
    end
end
