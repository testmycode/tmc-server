# frozen_string_literal: true

require 'spec_helper'
require 'gdocs_export'

describe GDocsExport, gdocs: true do
  before :all do
    @session = GDocsExport.authenticate []
    expect(@session).not_to be_nil
    @fixture1 = '0AnEpZul37faOdE1rc3lib0RLdjc5UXk2bk56a1lyWlE'
  end

  before :each do
    @course = FactoryGirl.create(:course)
  end

  describe 'finding stuff' do
    before :each do
      @course.spreadsheet_key = @fixture1
      @ss = GDocsExport.find_course_spreadsheet @session, @course
      @ws = @ss.worksheets.find { |w| w.title == '1' }
    end

    it 'should find students present in the fixture' do
      expect(GDocsExport.student_row(@ws, '13816074')).not_to eq(-1)
      expect(GDocsExport.student_row(@ws, '13284062')).not_to eq(-1)
    end
  end

  describe 'refreshing points' do
    it 'should not find a spreadsheet if spreadsheet_key is nil' do
      @course.spreadsheet_key = nil
      notifications = []
      GDocsExport.refresh_course_spreadsheet notifications, @session, @course
      expect(notifications).to include('exception: spreadsheet_key undefined')
    end

    it 'should find fixture1' do
      @course.spreadsheet_key = @fixture1
      notifications = []
      GDocsExport.refresh_course_spreadsheet notifications, @session, @course
      expect(notifications).to be_empty
    end
  end
end
