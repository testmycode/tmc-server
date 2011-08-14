require 'spec_helper'
require 'gdocs_backend'

describe GDocsBackend, :slow => true do
  before :all do
    @session = GDocsBackend.authenticate
    @session.should_not be_nil
  end

  def match_written_and_db_exercises(ws, course)
    w_exercises = GDocsBackend.written_exercises(ws)
    db_exercises = Exercise.course_gdocs_sheet_exercises(course, ws.title)
    db_exercises.each do |db_e|
      w_exercises[:exercises].should include(db_e.name)
      w_exercises[:points][db_e.name].should_not be_nil

      db_e.available_points.each do |db_point|
        w_exercises[:points][db_e.name].should include(db_point.name)
      end
    end
  end

  it "should be able to create and delete a spreadsheet" do
    course = Factory.create(:course, :name => "create_delete_spreadsheet")

    GDocsBackend.delete_course_spreadsheet(@session, course)
    ss = GDocsBackend.create_course_spreadsheet(@session, course)
    ss.should_not be_nil

    ss2 = GDocsBackend.find_course_spreadsheet(@session, course)
    ss2.title.should == ss.title

    GDocsBackend.delete_course_spreadsheet(@session, course)
    sheets = @session.spreadsheets.find_all {|ss| ss.title == course.name}
    sheets.should be_empty

    course.destroy
  end

  it "should be able to create and delete a worksheet" do
    course = Factory.create(:course, :name => "create_worksheet")
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

  describe "after updating an exercise worksheet" do
    before :all do
      @course = Factory.create(:course, :name => "worksheet_update")
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
                                    :user => @student1)
      @submission2 = Factory.create(:submission, :course => @course,
                                    :user => @student2)
      @submission3 = Factory.create(:submission, :course => @course,
                                    :user => @student3)
      @submission4 = Factory.create(:submission, :course => @course,
                                    :user => @student4)

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

      GDocsBackend.update_worksheet(@ws, @course)
      match_written_and_db_exercises(@ws, @course)
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
      GDocsBackend.find_student_row(@ws, @student1).should_not == -1
      GDocsBackend.find_student_row(@ws, @student2).should_not == -1
      GDocsBackend.find_student_row(@ws, @student3).should_not == -1
      GDocsBackend.find_student_row(@ws, @student4).should_not == -1
    end

    it "should not have a row for students not on the course" do
      student5 = Factory.create(:user)
      student6 = Factory.create(:user)
      GDocsBackend.find_student_row(@ws, student5).should == -1
      GDocsBackend.find_student_row(@ws, student6).should == -1
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
        GDocsBackend.update_worksheet(@ws, @course)
        GDocsBackend.find_point_col(@ws, ap5.name).should_not == -1
        GDocsBackend.find_point_col(@ws, ap6.name).should_not == -1
        match_written_and_db_exercises(@ws, @course)
        ap5.destroy
        ap6.destroy
        GDocsBackend.update_worksheet(@ws, @course)
        GDocsBackend.find_point_col(@ws, "ap5").should_not == -1
        GDocsBackend.find_point_col(@ws, "ap6").should_not == -1
        match_written_and_db_exercises(@ws, @course)
      end
    end
  end
end
