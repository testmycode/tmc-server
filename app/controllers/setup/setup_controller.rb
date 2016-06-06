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
        title: 'Info (todo link)',
        #path: :edit_setup_organization_course_detail,
        #options: {organization_id: 'hy', course_id: nil, id: 1}
        path: :new_setup_create_organization_path
      },
      {
        # step_number: 3,
        title: 'Deadlines',
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

    #TODO: Just temporary fixed course id
    #@course = Course.find 1

    for i in 0..step-1 do
      #byebug if i == 1
      add_breadcrumb (i+1).to_s+'. '+steps[i][:title], steps[i][:path]
    end

    # links = [ { '1. Course template': :setup_organization_course_chooser_index_path },
    #           { '2. Info': edit_setup_organization_course_detail_path(@organization.slug, @course.id) },
    #           { '3. Deadlines': edit_setup_organization_course_deadline_path(@organization.slug, @course.id)},
    #           { '4. Assistants': edit_setup_organization_course_assistant_path },
    #           { '5. Finish': nil }
    # ]

    # for i in 0..step-1 do
    #   add_breadcrumb links[i].each_key.first.to_s, links[i].each_value.first
    # end


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