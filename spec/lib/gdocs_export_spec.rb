require 'spec_helper'
require 'gdocs_export'

describe GDocsExport, :gdocs => true do
  before :all do
    @session = GDocsExport.authenticate
    @session.should_not be_nil
    @course = Factory.create(:course)
    @fixture1 = "0AnEpZul37faOdE1rc3lib0RLdjc5UXk2bk56a1lyWlE"
  end

  describe "refreshing points" do
    it "should not find a spreadsheet if spreadsheet_key is nil" do
      @course.spreadsheet_key = nil
      notifications = GDocsExport.refresh_course_spreadsheet @session, @course
      notifications.should include("error: spreadsheet_key undefined")
    end

    it "should find fixture1" do
      @course.spreadsheet_key = @fixture1
      notifications = GDocsExport.refresh_course_spreadsheet @session, @course
      notifications.should be_empty
    end
  end
end

