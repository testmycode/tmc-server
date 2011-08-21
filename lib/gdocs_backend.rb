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
    ss = gsession.create_spreadsheet course.name

    worksheets = ss.worksheets
    ws = ss.worksheets.first
    ws.title = "summary"
    ws.save
    worksheets[1, worksheets.size-1].each {|ws| ws.delete}
    return ss
  end

  def self.get_course_spreadsheet gsession, course
    ss = find_course_spreadsheet gsession, course
    return ss if ss
    create_course_spreadsheet gsession, course
  end

  def self.create_worksheet ss, sheetname
    ss.add_worksheet sheetname
  end

  def self.find_worksheet ss, sheetname
    ss.worksheets.find {|w| w.title == sheetname}
  end

  def self.get_worksheet ss, sheetname
    ws = find_worksheet ss, sheetname
    return ws if ws
    create_worksheet ss, sheetname
  end

  def self.delete_worksheet ss, sheetname
    ws = get_worksheet(ss, sheetname)
    ws.delete if ws
  end

  def self.refresh_course_spreadsheet course
    ss = get_course_spreadsheet authenticate, course
    students = get_spreadsheet_course_students ss, course

    course.gdocs_sheets.each do |sheetname|
      ws = get_worksheet ss, sheetname
      update_points_worksheet ws, course, students
      ws.save
    end
    update_summary_worksheet(ss, course, students).save
    return ss.human_url
  end

  def self.point_location ws, point_name, student
    {
      :row => find_student_row(ws, student.login),
      :col => find_point_col(ws, point_name)
    }
  end

  def self.add_point ws, point_name, student
    pos = point_location ws, point_name, student
    raise "no such student" if pos[:row] == -1
    raise "no such point" if pos[:col] == -1
    ws[pos[:row], pos[:col]] = "1"
  end

  def self.point_granted? ws, point_name, student
    pos = point_location ws, point_name, student
    if pos[:row] == -1 or pos[:col] == -1
      false
    else
      ws[pos[:row], pos[:col]] == "1"
    end
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
      return row if ws[row, student_col] == quote_prepend(student)
    end
    return -1
  end

  def self.get_spreadsheet_course_students ss, course
    students = ss.worksheets.reduce(Set.new) do |students, worksheet|
      students.merge(get_worksheet_students worksheet)
    end
    students.merge(User.course_students(course).map(&:login))
  end

  def self.get_worksheet_students ws
    (first_points_row .. ws.num_rows).reduce(Set.new) do |students, row|
      unless ws[row, student_col].empty?
        students << strip_quote(ws[row, student_col])
      end
      students
    end
  end

  def self.get_free_student_row ws
    (first_points_row .. ws.max_rows).each do |row|
      return row if ws[row, student_col] == ""
    end
    return ws.max_rows += 1
  end

  def self.add_student ws, student
    row = get_free_student_row(ws)
    ws[row, student_col] = quote_prepend(student)
  end

  def self.find_point_col ws, point_name
    for col in (first_points_col .. ws.num_cols)
      return col if ws[point_names_row, col] == quote_prepend(point_name)
    end
    return -1
  end

  def self.update_summary_worksheet ss, course, students
    ws = get_worksheet ss, 'summary'
    update_summary_sheetnames ws, course
    update_students ws, students
    update_summary_references ss, ws
    update_total_col ws
    return ws
  end

  def self.update_summary_sheetnames ws, course
    col = first_points_col
    course.gdocs_sheets.each do |sheetname|
      ws[exercise_names_row, col] = sheetname
      col += 1
    end
  end

  def self.summary_sum row, sheet
    search_range = "$#{col_num2str(student_col)}:$#{col_num2str(student_col)}"
    criteria = "$#{col_num2str(student_col)}#{row}"
    sum_range = "$#{col_num2str(total_col)}:$#{col_num2str(total_col)}"
    "=sumif('#{sheet}'!#{search_range};#{criteria};'#{sheet}'!#{sum_range})"
  end

  def self.update_summary_references ss, summary_ws
    (first_points_col .. summary_ws.num_cols).each do |col|
      sheet_name = summary_ws[exercise_names_row,col]
      break if sheet_name == ""
      point_ws = get_worksheet ss, sheet_name

      (first_points_row .. summary_ws.num_rows).each do |row|
        student_name = summary_ws[row, student_col]
        break if student_name == ""
        summary_ws[row,col] = summary_sum row, point_ws.title
      end
    end
  end

  def self.update_points_worksheet ws, course, students
    update_available_points ws, course
    update_students ws, students
    update_points ws, course
    update_total_col ws
  end

  def self.update_available_points ws, course
    db_exercises = Exercise.course_gdocs_sheet_exercises(course, ws.title)
    w_exercises = written_exercises ws

    allocate_points_space ws, db_exercises, w_exercises
    blank_row ws, exercise_names_row
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

  def self.blank_row ws, row
    (1 .. ws.num_cols).each {|col| ws[row,col] = nil}
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
    (first_points_row..ws.num_rows).each do |row|
      first = "#{col_num2str(total_col+1)}#{row}"
      last = "#{col_num2str(ws.num_cols)}#{row}"
      ws[row,total_col] = "=sum(#{first}:#{last})"
    end
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

  def self.add_students ws, students
    students.each do |student|
      if find_student_row(ws, student) < 0
        add_student ws, student
      end
    end
  end

  def self.update_students ws, students
    add_students ws, students
    quote_prepend_students ws
    merge_duplicate_students ws
    # FIXME: merge duplicate students?
  end

  def self.quote_prepend_students ws
    (first_points_row .. ws.num_rows).each do |row|
      unless ws[row, student_col] =~ /^'/
        ws[row, student_col] = quote_prepend(ws[row,student_col])
      end
    end
  end

  def self.merge_duplicate_students ws
    (first_points_row .. ws.num_rows).each do |row1|
      student = ws[row1, student_col]
      next if student.empty?
      (row1+1 .. ws.num_rows).each do |row2|
        student2 = ws[row2, student_col]
        if student == student2
          merge_duplicate_student_rows ws, row1, row2
        end
      end
    end
  end

  def self.merge_duplicate_student_rows ws, r1, r2
    (first_points_col .. ws.num_cols).each do |col|
      ws[r1, col] = ws[r2, col] if ws[r1, col].empty?
    end
    blank_row ws, r2
  end

  def self.blank_row ws, row
    (1 .. ws.num_cols).each {|col| ws[row,col] = nil}
  end

  def self.compact_student_rows ws
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

  def self.col_num2str x
    raise "col_num2str not defined for numbers < 1" if x < 1

    s = ""
    while(x > 0)
      x -= 1
      s += (?A + (x % 26)).chr
      x /= 26
    end
    return s.reverse
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

