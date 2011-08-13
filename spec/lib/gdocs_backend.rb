require 'spec_helper'
require 'gdocs_backend'

describe GDocsBackend, :slow => true do
  before :all do
    #@session = GDocsBackend.create_session('','')
    @session.should_not be_nil
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

      @ap1_1 = Factory.create(:available_point, :exercise => @ex1)
      @ap1_2 = Factory.create(:available_point, :exercise => @ex1)
      @ap2_1 = Factory.create(:available_point, :exercise => @ex2)
      @ap2_2 = Factory.create(:available_point, :exercise => @ex2)

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
                               :name => @ap1_1.name, :user => @student1,
                               :submission => @submission1)
      @award2 = Factory.create(:awarded_point, :course => @course,
                               :name => @ap1_2.name, :user => @student2,
                               :submission => @submission2)
      @award3 = Factory.create(:awarded_point, :course => @course,
                               :name => @ap2_1.name, :user => @student3,
                               :submission => @submission3)
      @award4 = Factory.create(:awarded_point, :course => @course,
                               :name => @ap2_2.name, :user => @student4,
                               :submission => @submission4)

      GDocsBackend.update_worksheet(@ws, @course)
    end

    after :all do
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

    it "should contain all the users' awarded points" do
      GDocsBackend.point_granted?(@ws, @ap1_1.name, @student1).should be_true
      GDocsBackend.point_granted?(@ws, @ap1_2.name, @student2).should be_true
      GDocsBackend.point_granted?(@ws, @ap2_1.name, @student3).should be_true
      GDocsBackend.point_granted?(@ws, @ap2_2.name, @student4).should be_true
    end
  end
end

