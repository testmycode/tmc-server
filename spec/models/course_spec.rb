require 'spec_helper'

describe Course do

  before :all do
    @x = Course.count
  end

  before :each do
    @repo_dir = Dir.mktmpdir
    @cache_dir = Dir.mktmpdir

    @course = Course.new
    GitBackend.stub!(:repositories_root).and_return(@repo_dir)
    GitBackend.stub!(:cache_root).and_return(@cache_dir)
  end

  after :each do
    FileUtils.remove_entry_secure @repo_dir
    FileUtils.remove_entry_secure @cache_dir
  end

  it "has x amount to begin with" do
    Course.count.should == @x
  end

  it "has one more after adding one" do
    course = Course.create!(:name => 'TestCourse')
    Course.count.should == @x+1
    course.destroy #this is needed in order to destroy repository
  end

  it "has x amount after one was created in a previous example" do
    Course.count.should == @x
  end

  describe Course, "when it has repository" do
    before :each do
      @course = Course.new(:name => "testcourse")
      @course.create_repository
    end

    after :each do
      @course.delete_repository
    end
  end

  describe "Validations" do
    describe "with valid params" do
      it "course name 'TestCourse2' create" do
        course = nil
        expect {
          course = Course.create!(:name => 'TestCourse2')
        }.to change(Course, :count).by(1)
        course.destroy #this is needed in order to destroy repository
      end
    end

    describe "with invalid params" do
      it "name doesn't exist" do
        expect {
          Course.create
        }.to change(Course, :count).by(0)
      end

      it "name is too long" do
        tooLongName = 'a'*41
        expect {
          Course.create(:name => tooLongName)
        }.to change(Course, :count).by(0)
      end

      it "name has space in it" do
        spacedName = 'Test Course'
        expect {
          Course.create(:name => spacedName)
        }.to change(Course, :count).by(0)
      end

    end
  end

end
