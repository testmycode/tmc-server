module CoursesHelper
  def github_repo_url_to_project_page_url(url)
    if url =~ /github.com[:\/]([^\/]*)\/([^\/]*)\.git/
      "https://github.com/#{$1}/#{$2}"
    end
  end

  def gdocs_notifications notifications
    ret = "Refreshed points in google docs. "
    return ret if notifications.empty?
    ret += "Notifications:"
    ret += "<ul>"
    ret += notifications.map do |msg|
      if msg =~ /^error/ or msg =~ /^exception/
        "<li><b>#{msg}</b></li>"
      else
        "<li>#{msg}</li>"
      end
    end.join
    ret += "</ul>"
    return ret
  end
end
