# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'twitter_bootstrap_breadcrumbs'

describe BreadCrumbs, type: :controller do
  controller(ApplicationController) do
    # ApplicationController already includes BreadCrumbs.
  end

  def breadcrumb_urls
    controller.instance_variable_get(:@breadcrumbs).pluck(:url)
  end

  it 'keeps a path whose organization slug contains _path or _url as is' do
    controller.send(:add_breadcrumb, 'Organization', '/org/cs_path')
    controller.send(:add_breadcrumb, 'Organization', '/org/cs_url')
    expect(breadcrumb_urls).to eq(['/org/cs_path', '/org/cs_url'])
  end

  it 'calls the route helper a Symbol url names' do
    controller.send(:add_breadcrumb, 'TMC', :root_path)
    expect(breadcrumb_urls).to eq(['/'])
  end

  it 'keeps a Proc url' do
    url = ->(*_args) { }
    controller.send(:add_breadcrumb, 'Forgot password', url)
    expect(breadcrumb_urls).to eq([url])
  end
end
