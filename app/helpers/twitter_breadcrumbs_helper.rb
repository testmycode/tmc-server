# frozen_string_literal: true

module TwitterBreadcrumbsHelper
  def render_breadcrumbs(divider = '/')
    render partial: 'twitter-bootstrap/breadcrumbs', locals: { divider: divider }
  end
end
