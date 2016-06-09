class Setup::SetupController < ApplicationController

  before_action :set_organization

  def steps
    [
      {
        # step_number: 1,
        title: 'Template',
        path: :setup_organization_course_chooser_index
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
        path: :setup_organization_course_course_assistants
      },
      {
        # step_number: 5,
        title: 'Finish',
        path: nil
      }
    ]
  end

  def print_setup_breadcrumb(step = 0)

    add_breadcrumb 'Setup', :setup_path

    for i in 0..step-2 do
      add_breadcrumb (i+1).to_s+'. '+steps[i][:title], steps[i][:path]
    end
    add_breadcrumb (step).to_s+'. '+steps[step-1][:title]

    # links = [ { '1. Course template': :setup_organization_course_chooser_index_path },
    #           { '2. Info': edit_setup_organization_course_detail_path(@organization.slug, @course.id) },
    #           { '3. Deadlines': edit_setup_organization_course_deadline_path(@organization.slug, @course.id)},
    #           { '4. Assistants': edit_setup_organization_course_assistant_path },
    #           { '5. Finish': nil }
    # ]

  end

  def step_number(title)
    found = 0
    steps.each do | st |
      found += 1
      if (st[:title] == title)
        return found
      end
    end
    return nil
  end

  def link_to_next_step(step_number)
    #byebug
    return steps[step_number][:path]
  end

  def set_organization
    @organization = Organization.find_by(slug: params[:organization_id])
  end

  def set_course
    @course = Course.find(params[:course_id]) unless params[:course_id].nil?
  end

end