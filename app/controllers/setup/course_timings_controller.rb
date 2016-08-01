class Setup::CourseTimingsController < Setup::SetupController
  before_action :set_course

  def show
    authorize! :teach, @organization

    @setup_in_progress = setup_in_progress?
    if setup_in_progress?
      print_setup_phases(3)
    else
      add_course_breadcrumb
      add_breadcrumb('Timing')
    end
  end

  def update
    authorize! :teach, @organization

    print_setup_phases(3)

    if params[:commit] == 'Fill and preview'
      case params[:unlock_type]
      when 'no_unlocks'
        clear_all_unlocks
      when 'percent_from_previous'
        unlocks_previous_set_completed(80)
      end

      first_set_date = params[:first_set_date]
      case params[:deadline_type]
      when 'no_deadlines'
        clear_all_deadlines
      when 'weekly_deadlines'
        if first_set_date[0].blank?
          redirect_to setup_organization_course_course_timing_path, notice: 'Please insert first set date'
          return
        end
        fill_deadlines_with_interval(first_set_date, 7)
      when 'all_same_deadline'
        if first_set_date[0].blank?
          redirect_to setup_organization_course_course_timing_path, notice: 'Please insert first set date'
          return
        end
        fill_all_deadlines_with(first_set_date)
      end

      redirect_to setup_organization_course_course_timing_path, notice: 'Preview updated'

    elsif params[:commit] == 'Accept and continue'

      save_unlocks
      save_deadlines

      if setup_in_progress?
        redirect_to setup_organization_course_course_assistants_path(@organization, @course)
      else
        redirect_to organization_course_path(@organization, @course)
      end
    else
      raise 'Wrong button'
    end

  rescue UnlockSpec::InvalidSyntaxError => e
    redirect_to setup_organization_course_course_timing_path, alert: e.to_s
  rescue DeadlineSpec::InvalidSyntaxError => e
    redirect_to setup_organization_course_course_timing_path, alert: e.to_s
  end

  private

  def save_unlocks
    authorize! :manage_unlocks, @course

    groups = group_params
    groups.each do |name, conditions|
      array = Array(conditions['0'])
      @course.exercise_group_by_name(name).group_unlock_conditions = array.to_json
      UncomputedUnlock.create_all_for_course_eager(@course)
    end
  end

  def clear_all_unlocks
    authorize! :manage_unlocks, @course
    @course.exercise_groups.each do |eg|
      eg.group_unlock_conditions = [''].to_json
    end
  end

  def unlocks_previous_set_completed(percentage = 80)
    authorize! :manage_unlocks, @course
    prevname = nil
    @course.exercise_groups.each do |eg|
      eg.group_unlock_conditions = Array("#{percentage}% from #{prevname}").to_json unless prevname.nil?
      prevname = eg.name
    end
  end

  def save_deadlines
    authorize! :manage_deadlines, @course
    groups = group_params
    groups.each do |name, deadlines|
      hard_deadlines = [deadlines[:hard][:static], ''].to_json
      @course.exercise_group_by_name(name).hard_group_deadline = hard_deadlines
    end
  end

  def clear_all_deadlines
    authorize! :manage_deadlines, @course
    @course.exercise_groups.each do |eg|
      eg.hard_group_deadline = ['', ''].to_json
    end
  end

  def fill_deadlines_with_interval(first_date, days = 7)
    authorize! :manage_deadlines, @course
    date = first_date
    @course.exercise_groups.each do |eg|
      eg.hard_group_deadline = date.to_json
      date = Array((DateTime.parse(date[0]) + days.days).strftime('%Y-%m-%d'))
    end
  end

  def fill_all_deadlines_with(date)
    authorize! :manage_deadlines, @course
    @course.exercise_groups.each do |eg|
      eg.hard_group_deadline = date.to_json
    end
  end

  private

  def group_params
    sliced = params.slice(:group, :empty_group)
    groups = sliced[:group] || {}
    empty_group = sliced[:empty_group] || {}
    groups[''] = empty_group unless empty_group.empty?
    groups
  end
end
