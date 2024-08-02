# frozen_string_literal: true

require 'spec_helper'
require 'doc_gen'

describe 'User manual', type: :request, usermanual: true, integration: true do
  def make_page(name)
    doc = DocGen.new(name, self)
    doc.render_template(File.join(File.dirname(__FILE__), "#{name}.html.erb"))
  end

  it 'has a page for custom course creation manual' do
    make_page 'customcourse'
  end

  it 'has a page for admins' do
    make_page 'admins'
  end

  it 'has a page for teachers' do
    make_page 'teachers'
  end
end
