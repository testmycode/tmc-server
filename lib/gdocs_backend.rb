require 'google_spreadsheet'

module GDocsBackend

  def self.authenticate
    GoogleSpreadsheet.login(
      SandboxServer::Application.config.gdocs_username,
      SandboxServer::Application.config.gdocs_password)
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

  # FIXME: handle invalid location, test
  def self.add_point ws, point_name, student
    pos = point_location ws, point_name, student
    ws[pos[:row], pos[:col]] = "1"
  end

  # FIXME: test with row,col -1
  def self.point_granted? ws, point_name, student
    pos = point_location ws, point_name, student
    ws[pos[:row], pos[:col]] == "1"
  end

  def self.written_exercises ws
    hash = {
      :exercises => [],
      :points => {}
    }

    (first_points_col .. ws.num_cols).each do |col|
      exercise_name = strip_quote(ws[exercise_names_row, col])
      point_name = strip_quote(ws[point_names_row, col])

      if exercise_name != ""
        unless hash[:exercises].include? exercise_name
          hash[:exercises] << exercise_name
        end
        hash[:points][exercise_name] ||= []
      else
        exercise_name = hash[:exercises].last
      end

      if point_name != ""
        hash[:points][exercise_name] << point_name
      end
    end

    return hash
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
    db_exercises = Exercise.course_gdocs_sheet_exercises(course, ws.title)
    w_exercises = written_exercises ws

    allocate_points_space ws, db_exercises, w_exercises
    write_available_points ws, w_exercises
  end

  def self.allocate_points_space ws, db_exercises, w_exercises
    col = first_points_col
    db_exercises.each do |db_e|
      unless w_exercises[:exercises].include? db_e.name
        w_exercises[:exercises] << db_e.name
        w_exercises[:points][db_e.name] = db_e.available_points.map &:name
        next
      end

      new_points = db_e.available_points.map(&:name).select {|point_name|
          !w_exercises[:points][db_e.name].include?(point_name)
      }
      col += w_exercises[:points][db_e.name].size
      new_points.size.times{add_column ws, col}
      w_exercises[:points][db_e.name].concat(new_points)
      col += new_points.size
    end
  end

  def self.write_available_points ws, w_exercises
    col = first_points_col
    w_exercises[:exercises].each do |exercise_name|
      ws[exercise_names_row, col] = quote_prepend(exercise_name)
      w_exercises[:points][exercise_name].each do |point_name|
        ws[point_names_row, col] = quote_prepend(point_name)
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

  def self.strip_quote s
    s.sub(/^'/, '')
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
    puts ""
    for row in 1..ws.num_rows
      rows = ""
      for col in 1..ws.num_cols
        rows += ws[row, col].ljust(12) + "|"
      end
      puts rows
    end
  end
end

