# frozen_string_literal: true

require 'natsort'

module PointsHelper
  def github_repo_url_to_project_page_url(url)
    if url =~ /github.com[:\/]([^\/]*)\/([^\/]*)\.git/
      "https://github.com/#{Regexp.last_match(1)}/#{Regexp.last_match(2)}"
    end
  end

  def points_list(points)
    points.to_a.natsort.map { |pt| h(pt) }.join('&nbsp; ').html_safe
  end
end
