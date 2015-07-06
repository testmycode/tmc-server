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

  def points_list_obj(points)
    points.map do |pt|
      if pt.late?
        "<span class='late-points'>#{h(pt.name)}*</span>"
      else
        h(pt.name)
      end
    end.join('&nbsp; ').html_safe
  end

  def generate_csv_group(csv, group_name, users, sheets, sheet_points_for_user, total_points_for_user)
    csv << [group_name]
    csv << ['Username'] + sheets.map { |sheet| sheet[:name] } + ['Total']

    users.each do |user|
      points = sheets.map do |sheet|
        sheet_points_for_user.call(user.login, sheet[:name])
      end
      csv << [user.login] + points + [total_points_for_user.call(user.login)]
    end
    csv << ['']
  end
end
