require 'google_spreadsheet'

module GDocsBackend

  def self.create_session username, password
    GoogleSpreadsheet.login(username, password)
  end

  def self.delete_course_spreadsheet gsession, course
    sheets = gsession.spreadsheets.find_all {|s| s.title == course.name}
    sheets.each {|sheet| sheet.delete(true)}
  end

  def self.find_course_spreadsheet gsession, course
    gsession.spreadsheets.find {|s| s.title == course.name}
  end

  def self.create_course_spreadsheet gsession, course
    if find_course_spreadsheet(gsession, course)
      raise "course spreadsheet #{course.name} already exists, not creating"
    end
    gsession.create_spreadsheet course.name
  end

  def self.create_worksheet ss, sheetname
    ss.add_worksheet(sheetname)
  end

  def self.get_worksheet ss, sheetname
    ss.worksheets.find {|w| w.title == sheetname}
  end

  def self.delete_worksheet ss, sheetname
    ws = get_worksheet(ss, sheetname)
    ws.delete if ws
  end

  def self.point_location ws, point_name, student
    {
      :row => find_student_row(ws, student),
      :col => find_point_col(ws, point_name)
    }
  end

  def self.add_point ws, point_name, student
    pos = point_location ws, point_name, student
    ws[pos[:row], pos[:col]] = "1"
  end

  def self.point_granted? ws, point_name, student
    pos = point_location ws, point_name, student
    return ws[pos[:row], pos[:col]] == "1"
  end

  def self.update_points ws, course
    students = User.course_students(course)
    students.each do |student|
      user_points = AwardedPoint.course_user_points(course, student)
      user_points.each {|ap| add_point(ws, ap.name, student)}
    end
  end

  def self.find_student_row ws, student
    (first_points_row .. ws.num_rows).each do |row|
      return row if ws[row, student_col] == quote_prepend(student.login)
    end
    return -1
  end

  def self.get_free_student_row ws
    if ws.num_rows < first_points_row
      return first_points_row
    elsif ws.num_rows < ws.max_rows
      return ws.num_rows + 1
    else
      return ws.max_rows += 1
    end
  end

  def self.add_student_row ws, student
    row = get_free_student_row(ws)
    ws[row, student_col] = quote_prepend(student.login)
  end

  def self.find_point_col ws, point_name
    for col in (first_points_col .. ws.num_cols)
      return col if ws[point_names_row, col] == quote_prepend(point_name)
    end
    return -1
  end

  def self.find_student_row ws, student
    for row in (first_points_row .. ws.num_rows)
      return row if ws[row, student_col] == quote_prepend(student.login)
    end
    return -1
  end

  def self.update_worksheet ws, course
    update_available_points ws, course
    update_students ws, course
    update_points ws, course
    update_total_col ws
  end

  def self.update_available_points ws, course
    exercises = Exercise.course_gdocs_sheet_exercises(course, ws.title)
    col = first_points_col
    exercises.each do |exercise|
      ws[exercise_names_row, col] = quote_prepend(exercise.name)
      exercise.available_points.each do |ap|
        ws[point_names_row, col] = quote_prepend(ap.name)
        col += 1
      end
    end
  end

  def self.update_total_col ws
    ws[exercise_names_row, total_col] = "total"
    (first_points_row..ws.num_rows).each {|row| ws[row,total_col] = "s"}
  end

  def self.add_column ws, new_col
    ensure_col_capacity ws
    (new_col .. ws.num_cols).reverse_each {|col| copy_col_right(ws, col)}
    blank_col ws, new_col
  end

  def self.blank_col ws, col
    (1 .. ws.num_rows).each {|row| ws[row,col] = nil}
  end

  def self.copy_col_right ws, col
    (1 .. ws.num_rows).each {|row| ws[row,col+1] = ws[row,col]}
  end

  # FIXME: check if bounds checking is neccessary at all
  def self.ensure_col_capacity ws
    if ws.num_cols == ws.max_cols
      ws.max_cols += 1
    end
  end

  def self.add_students ws, course
    User.course_students(course).each do |student|
      if find_student_row(ws, student) < 0
        add_student_row ws, student
      end
    end
  end

  def self.update_students ws, course
    add_students ws, course
    # FIXME: merge duplicate students?
  end

  def self.quote_prepend s
    "'#{s}"
  end

  def self.student_col
    1
  end

  def self.total_col
    student_col + 1
  end

  def self.first_points_col
    total_col + 1
  end

  def self.exercise_names_row
    1
  end

  def self.point_names_row
    exercise_names_row + 1
  end

  def self.first_points_row
    point_names_row + 1
  end

  def self.print_worksheet(ws)
    for row in 1..ws.num_rows
      rows = ""
      for col in 1..ws.num_cols
        rows += ws[row, col].ljust(8) + "|"
      end
      puts rows
    end
  end
end

