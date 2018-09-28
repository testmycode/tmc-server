# frozen_string_literal: true

require 'google_spreadsheet'

module GDocsExport
  def self.authenticate(notifications)
    notifications << 'gdocs_username undefined' && (return nil) unless
      TmcServer::Application.config.gdocs_username
    notifications << 'gdocs_password undefined' && (return nil) unless
      TmcServer::Application.config.gdocs_password

    GoogleSpreadsheet.login(
      TmcServer::Application.config.gdocs_username,
      TmcServer::Application.config.gdocs_password
    )
  end

  def self.refresh_course_worksheet_points(course, sheetname)
    return ["sheetname #{sheetname} not found"] unless
      course.gdocs_sheets.include?(sheetname)

    notifications = []
    gsession = authenticate notifications
    refresh_course_worksheet notifications, gsession, course, sheetname
    notifications
  end

  def self.refresh_course_worksheet(notifications, gsession, course, sheetname)
    ss = find_course_spreadsheet gsession, course
    update_worksheet notifications, ss, course, sheetname
  rescue Exception => e
    notifications << "exception: #{e.message}"
  end

  def self.worksheet_points(notifications, ws, course, sheetname)
    points = AvailablePoint.course_sheet_points_list(course, sheetname).map(&:name)
    points.each_with_object([]) do |point, result|
      if point_col(ws, point) < 0
        notifications << "point #{point} not found on sheet #{sheetname}"
      else
        result << point
      end
    end
  end

  def self.worksheet_students(notifications, ws, course, sheetname)
    students = User.course_sheet_students(course, sheetname)
    students.each_with_object([]) do |student, result|
      if student_row(ws, student.login) < 0
        notifications << "student #{student.login} not found on sheet " +
                         sheetname
      else
        result << student
      end
    end
  end

  def self.update_worksheet(notifications, ss, course, sheetname)
    ws = ss.worksheets.find { |w| w.title == sheetname }
    notifications << ["worksheet #{sheetname} not found"] && return unless ws

    students = worksheet_students notifications, ws, course, sheetname
    points = worksheet_points notifications, ws, course, sheetname

    write_points(ws, course, students, points)
    ws.save

    notifications
  end

  def self.write_points(ws, course, students, points)
    students.each do |student|
      row = student_row ws, student.login
      raise "student #{student.login} not found" if row < 0
      awarded = AwardedPoint.course_user_sheet_points(course, student, ws.title).map(&:name)
      points.each do |point|
        next unless awarded.include? point
        col = point_col ws, point
        raise "point #{point.name} not found" if col < 0
        ws[row, col] = '1' if ws[row, col] != '1'
      end
    end
  end

  def self.point_col(ws, point_name)
    (points_begin..ws.num_cols).each do |col|
      return col if ws[header_row, col] == point_name
      return col if ws[header_row, col] == "'#{point_name}"
    end
    -1
  end

  def self.student_row(ws, student_name)
    stripped = strip_leading_zeroes(student_name)
    return -1 if stripped.empty?

    (header_row + 1..ws.num_rows).each do |row|
      cell = ws[row, student_col]
      break if cell =~ /^=counta/
      return row if cell == student_name || cell == stripped
    end
    -1
  end

  def self.strip_leading_zeroes(s)
    s.gsub(/^0*/, '')
  end

  def self.find_course_spreadsheet(gsession, course)
    raise 'spreadsheet_key undefined' unless course.spreadsheet_key
    ss = gsession.spreadsheet_by_key course.spreadsheet_key
    raise 'spreadsheet not found' unless ss
    ss
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
end
