# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe Setup::SetupController, type: :controller do
  before do
    controller.instance_variable_set(:@organization, Organization.new(slug: 'hy'))
    controller.instance_variable_set(:@course, Course.new(id: 42))
  end

  def phase_urls
    controller.instance_variable_get(:@course_setup_phases).map { |phase| phase[:url] }
  end

  it 'calls the route helper with the organization and course when asked to pass them' do
    controller.add_phase('2. Details', 'visited', :edit_setup_organization_course_course_details_path, pass_parameters: true)
    expect(phase_urls).to eq(['/setup/hy/courses/42/course_details/edit'])
  end

  it 'calls the route helper without arguments otherwise' do
    controller.add_phase('Start', 'visited', :setup_start_index_path)
    expect(phase_urls).to eq(['/setup/start'])
  end

  it 'leaves a phase without a route helper unlinked' do
    controller.add_phase('3. Assistants', 'unavailable', nil, pass_parameters: true)
    expect(phase_urls).to eq([nil])
  end
end
