require 'google_spreadsheet'

class GDocs
  include GoogleSpreadsheet

  def initialize
    @disabled = false
    self.setup
  end

  def add_points_to_student(course_name, student_id, sheet_id, exercise)
    if @disabled
      return true
    end
    if validate_attributes({ :course_name => course_name,
                             :student_id  => student_id,
                             :sheet_id    => sheet_id,
                             :exercise    => exercise, 
                             :points      => "0"})
      return false
    end

    student_id = student_id.sub(/0*/, '')

    doc = self.get_document_from_google(course_name)
    if doc == nil
      raise RuntimeError, 'Cannot find right document. Missing document name is ' + course_name
      return false
    end

    sheet = get_worksheet(doc, sheet_id)
    if sheet == nil 
      raise RuntimeError, 'Cannot find right worksheet. Missing sheet in document ' + course_name + ' is ' + sheet_id.to_s
      return false 
    end

    if student_exists?(sheet, student_id)
      row = student_row(sheet, student_id)

      col = exercise_column(sheet, exercise)
      if col == -1
        raise RuntimeError, 'Cannot find exercise ' + exercise + ' in document ' + course_name
        return false
      end

      if cell_empty?(sheet, row, col)
        sheet[row, col] = 1
        sheet.save
        return true
      else
        raise RuntimeError, 'Cell is not empty'
        return false
      end
    else
      raise RuntimeError, "Student doesn't exist in worksheet. " + 
        "Missing student id in document " + course_name + " is " + student_id
      return false
    end
  end

  def create_new_spreadsheet(course_name)
    if @disabled
      return true
    end
    if self.get_document_from_google(course_name) == nil
      doc = self.get_document_from_google("Model")
      doc.duplicate(course_name)
      return true
    end
  end

  def get_document_from_google(course_name)
    docs = @account.spreadsheets("title" => course_name)
    docs.each do |doc|
      if doc.title == course_name
        return doc
      end
    end
    return nil
  end

  def setup
    if !@disabled
      @account = GoogleSpreadsheet.login('pajaohtu@gmail.com', 'qwerty1234567')
    end
  end

  def get_worksheet(document, sheet_id)
    document.worksheets.each do |sheet|
      if sheet.title == sheet_id.to_s
        return sheet
      end
    end
    return nil
  end

  def student_exists?(sheet, student_id)
    self.student_row(sheet, student_id) > 0
  end

  def student_row(sheet, student_id)
    col = find_students(sheet)
    if col == -1
      return -1
    end

    for row in 3..sheet.max_rows
      if sheet[row, col] == student_id.to_s
        return row
      end
    end
    return -1
  end

  def exercise_column(sheet, exercise)
    for col in 1..sheet.max_cols
      if sheet[2, col] == exercise
        return col
      end
    end
    return -1
  end

  def cell_empty?(sheet, row, col)
    sheet[row, col] == ""
  end

  def find_exercises_start(sheet)
    for col in 1..sheet.num_cols
      if sheet[1, col] == 'pajatehtävät'
        return col
      end
    end
    return -1
  end

  def find_students(sheet)
    for col in 1..sheet.num_cols
      if sheet[2, col] == 'Opnro'
        return col
      end
    end
    return -1
  end

  def validate_attributes(attr = {})
    cn = attr[:course_name]
    si = attr[:student_id]
    we = attr[:sheet_id]
    ex = attr[:exercise]
    po = attr[:points]

    if cn == nil or cn == ""
      return true end
    if si == nil
      return true end
    if we == nil
      return true end
    if ex == nil
      return true end
    if po == nil
      return true end
    return false
  end
end

