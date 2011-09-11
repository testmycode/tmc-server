require 'spec_helper'

describe AvailablePoint do
  describe "sorting" do
    it "should sort as intended" do
      a = [ Factory.create(:available_point, :name => "1.2"),
            Factory.create(:available_point, :name => "1.20"),
            Factory.create(:available_point, :name => "1.3")].sort!

      a.first.name.should == "1.2"
      a.last.name.should == "1.20"
    end
  end

  describe "scopes" do
    it "course_sheet_points" do
      course = Factory.create(:course)
      ex1 = Factory.create(:exercise, :course => course, :gdocs_sheet => "s1")
      ex2 = Factory.create(:exercise, :course => course, :gdocs_sheet => "s2")

      ap1 = Factory.create(:available_point, :exercise => ex1)
      ap2 = Factory.create(:available_point, :exercise => ex2)

      a = AvailablePoint.course_sheet_points(course, "s1")
      a.size.should == 1
      a.should include(ap1)

      a = AvailablePoint.course_sheet_points(course, "s2")
      a.size.should == 1
      a.should include(ap2)
    end
  end
end

