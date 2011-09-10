require 'google_spreadsheet'

module GDocsExport

  def self.authenticate
    raise "gdocs_username undefined" unless
      SandboxServer::Application.config.gdocs_username
    raise "gdocs_password undefined" unless
      SandboxServer::Application.config.gdocs_password

    GoogleSpreadsheet.login(
      SandboxServer::Application.config.gdocs_username,
      SandboxServer::Application.config.gdocs_password)
  end

  def self.refresh_course_points course
    notifications = []
    begin
      gsession = authenticate
      notifications.concat(refresh_course_spreadsheet(gsession, course))
    rescue Exception => e
      notifications << e.message
    end

    return notifications
  end

  def self.refresh_course_spreadsheet gsession, course
    notifications = []
    begin
      ss = find_course_spreadsheet gsession, course
      course.gdocs_sheets.each do |sheetname|
        notifications.concat(update_worksheet ss, course, sheetname)
      end
    rescue Exception => e
      notifications << e.message
    end
    return notifications
  end

  def self.update_worksheet ss, course, sheetname
    ws = ss.worksheets.find {|w| w.title == sheetname}
    return ["worksheet #{sheetname} not found"] unless ws

    student_col = find_student_col ws
    return ["student column not found"] if student_col < 0

    points = course.available_points
    points.each do |point|
    end

    User.course_students(course).each do |student|
    end

  end

  def self.student_col
    3
  end

  def self.header_row
    2
  end

  def self.points_begin
    6
  end

  def self.find_course_spreadsheet gsession, course
    raise "error: spreadsheet_key undefined" unless course.spreadsheet_key
    ss = gsession.spreadsheet_by_key course.spreadsheet_key
    raise "error: spreadsheet not found" unless ss
  end
end

