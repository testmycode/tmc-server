require 'spec_helper'

describe Course do

  let(:remote_repo_path) { "#{@test_tmp_dir}/fake_remote_repo" }
  let(:remote_repo_url) { "file://#{remote_repo_path}" }

  it "can be created with just a name parameter" do
    Course.create!(:name => 'TestCourse')
  end

  describe "gdocs_sheets" do
    it "should list all unique gdocs_sheets of a course" do
      course = Factory.create(:course)
      ex1 = Factory.create(:exercise, :course => course,
                           :gdocs_sheet => "sheet1")
      ex2 = Factory.create(:exercise, :course => course,
                           :gdocs_sheet => "sheet1")
      ex3 = Factory.create(:exercise, :course => course,
                           :gdocs_sheet => "sheet2")
      worksheets = course.gdocs_sheets

      worksheets.size.should == 2
      worksheets.should include("sheet1")
      worksheets.should include("sheet2")
    end
  end

  describe "when given no remote repo url" do
    it "should create a local repository when created" do
      course = Course.create!(:name => 'TestCourse')
      course.should have_local_repo
      course.should_not have_remote_repo
      course.bare_url.should == "file://#{course.bare_path}"
      File.should exist(course.bare_path)
    end

    it "should delete the repository when destroyed" do
      course = Course.create!(:name => 'TestCourse')
      repo_path = course.bare_path
      course.destroy
      File.should_not exist(repo_path)
    end
  end

  describe "when given a blank remote repo url" do
    it "should save and treat is as nil" do
      course = Course.create!(:name => 'MyCourse', :remote_repo_url => '')
      course.remote_repo_url.should be_nil
      course.should_not have_remote_repo
    end
  end

  describe "when given a remote repo url" do
    let(:course) { Course.create!(:name => 'TestCourse', :remote_repo_url => remote_repo_url) }

    it "should not create a local repository" do
      course.should have_remote_repo
      course.should_not have_local_repo
      course.bare_path.should be_nil
      course.bare_url.should == remote_repo_url
      File.should_not exist("#{GitBackend.repositories_root}/TestCourse.git")
    end

    it "should not attempt to destroy a local repository when destroyed" do
      local_repo_path = "#{GitBackend.repositories_root}/TestCourse.git"
      FileUtils.mkdir local_repo_path
      course.destroy
      File.should exist(local_repo_path)
    end
  end

  it "should be visible if not hidden and hide_after is nil" do
    c = Factory.create(:course, :hidden => false, :hide_after => nil)
    c.should be_visible
  end

  it "should be visible if not hidden and hide_after has not passed" do
    c = Factory.create(:course, :hidden => false, :hide_after => Time.now + 2.minutes)
    c.should be_visible
  end

  it "should not be visible if hidden" do
    c = Factory.create(:course, :hidden => true, :hide_after => nil)
    c.should_not be_visible
  end

  it "should be expired if hide_after has passed" do
    c = Factory.create(:course, :hidden => false, :hide_after => Time.now - 2.minutes)
    c.should_not be_visible
  end

  it "should accept Finnish dates and datetimes for hide_after" do
    c = Factory.create(:course)
    c.hide_after = "19.8.2012"
    c.hide_after.day.should == 19
    c.hide_after.month.should == 8
    c.hide_after.year.should == 2012

    c.hide_after = "15.9.2011 19:15"
    c.hide_after.day.should == 15
    c.hide_after.month.should == 9
    c.hide_after.hour.should == 19
    c.hide_after.year.should == 2011
  end

  it "should consider a hide_after date without time to mean the end of that day" do
    c = Factory.create(:course, :hide_after => "18.11.2013")
    c.hide_after.hour.should == 23
    c.hide_after.min.should == 59
  end


  describe "validation" do
    it "requires a name" do
      should_be_invalid_params({})
    end

    it "requires name to be reasonably short" do
      should_be_invalid_params(:name => 'a'*41)
    end

    it "requires name to be non-unique" do
      Course.create!(:name => 'TestCourse')
      should_be_invalid_params(:name => 'TestCourse')
    end

    it "forbids spaces in the name" do # this could eventually be lifted as long as everything else is made to tolerate spaces
      should_be_invalid_params(:name => 'Test Course')
    end

    def should_be_invalid_params(params)
      expect { Course.create!(params) }.to raise_error
    end
  end

end
