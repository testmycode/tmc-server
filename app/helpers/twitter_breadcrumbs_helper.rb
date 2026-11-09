# typed: strict
# frozen_string_literal: true

module TwitterBreadcrumbsHelper
  extend T::Sig

  sig { params(divider: String).returns(ActiveSupport::SafeBuffer) }
  def render_breadcrumbs(divider = '/')
    render partial: 'twitter-bootstrap/breadcrumbs', locals: { divider: divider }
  end
end
