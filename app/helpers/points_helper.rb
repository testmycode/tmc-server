module PointsHelper
  def github_repo_url_to_project_page_url(url)
    if url =~ /github.com[:\/]([^\/]*)\/([^\/]*)\.git/
      "https://github.com/#{$1}/#{$2}"
    end
  end

  def gdocs_notifications(notifications)
    ret = "<span class='flash notice'><ul>"
    ret += notifications.map do |msg|
      if msg =~ /^error/ || msg =~ /^exception/
        "<span class='error'><li>#{msg}</li></span>"
      else
        "<li>#{msg}</li>"
      end
    end.join
    ret += '</ul></span>'
    ret
  end

  def points_list(points)
    points.map { |pt| h(pt) }.join('&nbsp; ').html_safe
  end
end
