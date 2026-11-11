# typed: strict
# frozen_string_literal: true

require 'natsort'

module PointsHelper
  extend T::Sig
  sig { params(url: T.nilable(String)).returns(T.nilable(String)) }
  def github_repo_url_to_project_page_url(url)
    if url =~ /github.com[:\/]([^\/]*)\/([^\/]*)\.git/
      "https://github.com/#{Regexp.last_match(1)}/#{Regexp.last_match(2)}"
    end
  end

  sig { params(points: T::Enumerable[String]).returns(ActiveSupport::SafeBuffer) }
  def points_list(points)
    points.to_a.natsort.map { |pt| h(pt) }.join('&nbsp; ').html_safe
  end
end
