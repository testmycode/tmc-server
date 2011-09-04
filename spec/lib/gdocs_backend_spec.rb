require 'spec_helper'
require 'gdocs_backend'

describe GDocsBackend, :gdocs => true do
  before :all do
    @session = GDocsBackend.authenticate
    @session.should_not be_nil
    @prefix = GDocsBackend.find_temp_prefix @session
  end

  def match_written_and_db_points(ws, course)
    ws_points = GDocsBackend.points_from_worksheet(ws)
    exercises = Exercise.course_gdocs_sheet_exercises(course, ws.title)
    exercises.each do |e|
      e.available_points.each do |point|
        ws_points.should include(point.name)
      end
    end
  end

  describe "creating and deleting spreadsheets" do
    before :all do
      @course = Factory.create(:course, :name => "#{@prefix}-1")
    end

    after :all do
      GDocsBackend.delete_course_spreadsheet(@session, @course)
      @course.destroy
    end

    it "should be able to create and delete a spreadsheet" do
      GDocsBackend.delete_course_spreadsheet(@session, @course)
      ss = GDocsBackend.create_course_spreadsheet(@session, @course)
      ss.should_not be_nil

      ss2 = GDocsBackend.find_course_spreadsheet(@session, @course)
      ss2.title.should == ss.title

      GDocsBackend.delete_course_spreadsheet(@session, @course)
      sheets = @session.spreadsheets.find_all {|ss| ss.title == @course.name}
      sheets.should be_empty
    end

    it "newly created spreadsheet should only contain a summary worksheet" do
      ss = GDocsBackend.get_course_spreadsheet(@session, @course)
      worksheets = ss.worksheets
      worksheets.size.should == 1
      worksheets.first.title.should == 'summary'
    end
  end

  it "should be able to create and delete a worksheet" do
    course = Factory.create(:course, :name => "#{@prefix}-2")
    sheetname = "test_week"

    GDocsBackend.delete_course_spreadsheet(@session, course)
    ss = GDocsBackend.create_course_spreadsheet(@session, course)
    ss.should_not be_nil

    ws = GDocsBackend.create_worksheet(ss, sheetname)
    ws.title.should == sheetname
    ws.save

    ss.delete(true)
    course.destroy
  end

  describe "after course spreadsheet is refreshed" do
    before :all do
      @course = Factory.create(:course, :name => "#{@prefix}-3")
      @sheet1 = "week1"
      @sheet2 = "week2"
      @ex1 = Factory.create(:exercise, :course => @course,
                            :gdocs_sheet => @sheet1)
      @ex2 = Factory.create(:exercise, :course => @course,
                            :gdocs_sheet => @sheet2)
      @user = Factory.create(:user)
    end

    before :each do
      GDocsBackend.delete_course_spreadsheet(@session, @course)
      @ss = GDocsBackend.create_course_spreadsheet(@session, @course)
      @course.refresh_gdocs
    end

    after :all do
      @course.destroy
    end

    it "should create all the worksheets of the course" do
      worksheet_names = @ss.worksheets.map &:title
      worksheet_names.should include(@sheet1)
      worksheet_names.should include(@sheet2)
      worksheet_names.should include("summary")
    end

    it "should merge duplicate student rows" do
      ws = GDocsBackend.find_worksheet @ss, @sheet1
      ws.should_not be_nil

      row1 = GDocsBackend.get_free_student_row(ws)
      ws[row1, GDocsBackend.student_col] = GDocsBackend.
        quote_prepend(@user.login)

      row2 = GDocsBackend.get_free_student_row(ws)
      ws[row2, GDocsBackend.student_col] = GDocsBackend.
        quote_prepend(@user.login)
      ws.save

      row1, row2 = row2, row1 if row1 > row2

      @course.refresh_gdocs
      @ss = GDocsBackend.find_course_spreadsheet(@session, @course)
      ws = GDocsBackend.find_worksheet @ss, @sheet1

      ws[row1, GDocsBackend.student_col].
        should == GDocsBackend.quote_prepend(@user.login)
      ws[row2, GDocsBackend.student_col].
        should_not == GDocsBackend.quote_prepend(@user.login)
    end

    it "should remove student rows without students" do
      ws = GDocsBackend.find_worksheet @ss, @sheet1
      ws.should_not be_nil

      GDocsBackend.blank_row ws, GDocsBackend.first_points_row
      ws[GDocsBackend.first_points_row, GDocsBackend.student_col].
        should == ""

      @course.refresh_gdocs
      @ss = GDocsBackend.find_course_spreadsheet(@session, @course)
      ws = GDocsBackend.find_worksheet @ss, @sheet1

      ws[GDocsBackend.first_points_row, GDocsBackend.student_col].
        should_not == GDocsBackend.quote_prepend(@user.login)
    end

    it "should quote prepend student names" do
      ws = GDocsBackend.find_worksheet @ss, @sheet1
      ws.should_not be_nil

      row = GDocsBackend.get_free_student_row(ws)
      ws[row, GDocsBackend.student_col] = @user.login
      ws.save

      @course.refresh_gdocs
      @ss = GDocsBackend.find_course_spreadsheet(@session, @course)
      ws = GDocsBackend.find_worksheet @ss, @sheet1

      ws[row, GDocsBackend.student_col].
        should == GDocsBackend.quote_prepend(@user.login)
    end

    it "should add manually added students to each sheet" do
      ws = GDocsBackend.find_worksheet @ss, @sheet1
      ws.should_not be_nil

      GDocsBackend.add_student ws, @user.login
      ws.save

      @course.refresh_gdocs
      @ss = GDocsBackend.find_course_spreadsheet(@session, @course)
      @ss.worksheets.each do |ws|
        GDocsBackend.get_worksheet_students(ws).should include(@user.login)
      end
    end
  end

  describe "after updating an exercise worksheet" do
    before :all do
      @course = Factory.create(:course, :name => "#{@prefix}-4")
      GDocsBackend.delete_course_spreadsheet(@session, @course)
      @ss = GDocsBackend.create_course_spreadsheet(@session, @course)
      @sheetname = "week1"
      @ws = GDocsBackend.create_worksheet(@ss, @sheetname)

      @ex1 = Factory.create(:exercise, :course => @course,
                            :gdocs_sheet => @sheetname)
      @ex2 = Factory.create(:exercise, :course => @course,
                            :gdocs_sheet => @sheetname)

      @ap1 = Factory.create(:available_point, :exercise => @ex1)
      @ap2 = Factory.create(:available_point, :exercise => @ex1)
      @ap3 = Factory.create(:available_point, :exercise => @ex2)
      @ap4 = Factory.create(:available_point, :exercise => @ex2)

      @student1 = Factory.create(:user)
      @student2 = Factory.create(:user)
      @student3 = Factory.create(:user)
      @student4 = Factory.create(:user)

      @submission1 = Factory.create(:submission, :course => @course,
                                    :exercise => @ex1, :user => @student1)
      @submission2 = Factory.create(:submission, :course => @course,
                                    :exercise => @ex1, :user => @student2)
      @submission3 = Factory.create(:submission, :course => @course,
                                    :exercise => @ex2, :user => @student3)
      @submission4 = Factory.create(:submission, :course => @course,
                                    :exercise => @ex2, :user => @student4)

      @award1 = Factory.create(:awarded_point, :course => @course,
                               :name => @ap1.name, :user => @student1,
                               :submission => @submission1)
      @award2 = Factory.create(:awarded_point, :course => @course,
                               :name => @ap2.name, :user => @student2,
                               :submission => @submission2)
      @award3 = Factory.create(:awarded_point, :course => @course,
                               :name => @ap3.name, :user => @student3,
                               :submission => @submission3)
      @award4 = Factory.create(:awarded_point, :course => @course,
                               :name => @ap4.name, :user => @student4,
                               :submission => @submission4)

      students = GDocsBackend.get_spreadsheet_course_students(@ss, @course)
      GDocsBackend.update_points_worksheet(@ws, @course, students)
      match_written_and_db_points(@ws, @course)
    end

    after :all do
      @ws.save
      @course.destroy
    end

    it "should have all the available exercise points" do
      @ex1.available_points.each do |ap|
        GDocsBackend.find_point_col(@ws, ap.name).should_not == -1
      end
      @ex2.available_points.each do |ap|
        GDocsBackend.find_point_col(@ws, ap.name).should_not == -1
      end
    end

    it "should have a row for every student" do
      GDocsBackend.find_student_row(@ws, @student1.login).should_not == -1
      GDocsBackend.find_student_row(@ws, @student2.login).should_not == -1
      GDocsBackend.find_student_row(@ws, @student3.login).should_not == -1
      GDocsBackend.find_student_row(@ws, @student4.login).should_not == -1
    end

    it "should not have a row for students not on the course" do
      student5 = Factory.create(:user)
      student6 = Factory.create(:user)
      GDocsBackend.find_student_row(@ws, student5.login).should == -1
      GDocsBackend.find_student_row(@ws, student6.login).should == -1
    end

    it "should contain all of the points students have been awarded" do
      GDocsBackend.point_granted?(@ws, @ap1.name, @student1).should be_true
      GDocsBackend.point_granted?(@ws, @ap2.name, @student2).should be_true
      GDocsBackend.point_granted?(@ws, @ap3.name, @student3).should be_true
      GDocsBackend.point_granted?(@ws, @ap4.name, @student4).should be_true
    end

    it "should not contain points the students havent earned" do
      GDocsBackend.point_granted?(@ws, @ap4.name, @student1).should be_false
      GDocsBackend.point_granted?(@ws, @ap3.name, @student2).should be_false
      GDocsBackend.point_granted?(@ws, @ap2.name, @student3).should be_false
      GDocsBackend.point_granted?(@ws, @ap1.name, @student4).should be_false
    end

    describe "when new available points are introduced" do
      it "should contain the added points even after their deletion" do
        ap5 = Factory.create(:available_point, :exercise => @ex1,
                             :name => "ap5")
        ap6 = Factory.create(:available_point, :exercise => @ex1,
                             :name => "ap6")
        students = GDocsBackend.get_spreadsheet_course_students(@ss, @course)

        GDocsBackend.update_points_worksheet(@ws, @course, students)
        GDocsBackend.find_point_col(@ws, ap5.name).should_not == -1
        GDocsBackend.find_point_col(@ws, ap6.name).should_not == -1
        match_written_and_db_points(@ws, @course)
        ap5.destroy
        ap6.destroy
        GDocsBackend.update_points_worksheet(@ws, @course, students)
        GDocsBackend.find_point_col(@ws, "ap5").should_not == -1
        GDocsBackend.find_point_col(@ws, "ap6").should_not == -1
        match_written_and_db_points(@ws, @course)
      end
    end
  end

  describe "helpers" do
    it "should be able to transform numbers > 0 to column letters" do
      lambda { GdocsBackend.col_num2str(0) }.should raise_error
      GDocsBackend.col_num2str(1).should == "A"
      GDocsBackend.col_num2str(2).should == "B"
      GDocsBackend.col_num2str(3).should == "C"
      GDocsBackend.col_num2str(4).should == "D"
      GDocsBackend.col_num2str(5).should == "E"
      GDocsBackend.col_num2str(6).should == "F"
      GDocsBackend.col_num2str(7).should == "G"
      GDocsBackend.col_num2str(8).should == "H"
      GDocsBackend.col_num2str(9).should == "I"

      GDocsBackend.col_num2str(10).should == "J"
      GDocsBackend.col_num2str(11).should == "K"
      GDocsBackend.col_num2str(12).should == "L"
      GDocsBackend.col_num2str(13).should == "M"
      GDocsBackend.col_num2str(14).should == "N"
      GDocsBackend.col_num2str(15).should == "O"
      GDocsBackend.col_num2str(16).should == "P"
      GDocsBackend.col_num2str(17).should == "Q"
      GDocsBackend.col_num2str(18).should == "R"
      GDocsBackend.col_num2str(19).should == "S"

      GDocsBackend.col_num2str(20).should == "T"
      GDocsBackend.col_num2str(21).should == "U"
      GDocsBackend.col_num2str(22).should == "V"
      GDocsBackend.col_num2str(23).should == "W"
      GDocsBackend.col_num2str(24).should == "X"
      GDocsBackend.col_num2str(25).should == "Y"
      GDocsBackend.col_num2str(26).should == "Z"
      GDocsBackend.col_num2str(27).should == "AA"
      GDocsBackend.col_num2str(28).should == "AB"
      GDocsBackend.col_num2str(29).should == "AC"
      GDocsBackend.col_num2str(30).should == "AD"
    end
  end
end

