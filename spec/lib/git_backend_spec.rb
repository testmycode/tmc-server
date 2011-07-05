require 'spec_helper'

describe GitBackend do

  before :each do
    @test_exercises = "#{::Rails.root}/testdata/exercises"

    @course = Course.new #TODO: use an empty class instead
    @course.name = 'testcourse'
  end

  describe "#create_local_repository" do

    it "should create a repository" do
      @course.create_local_repository
      File.should exist(@course.bare_path)
      File.should exist("#{@course.bare_path}/objects")
    end

    it "should raise an exception if the repo already exists" do
      FileTest.stub!(:exists?).and_return(true)
      lambda { @course.create_local_repository }.should raise_error
    end

    it "should raise an exception if console commands fail" do
      path = ENV['PATH']
      system("true").should be_true
      begin
        ENV['PATH'] = ''
        system("true").should be_false
        lambda { @course.create_local_repository }.should raise_error
      ensure
        ENV['PATH'] = path
      end
    end
  end

  describe "#bare_path" do
    it "should give a bare path" do
      @course.bare_path.include?(".git").should be_true
      @course.bare_path.include?(GitBackend.repositories_root).should be_true
      @course.bare_path.include?(@course.name).should be_true
    end
  end
  
  describe "paths used" do
    it "should be absolute" do
      class_paths = [
        :repositories_root,
        :model_repository,
        :hooks_dir,
        :cache_root
      ]
      for path in class_paths
        GitBackend.send(path).should match /^\//
      end
      
      object_paths = [
        :cache_path,
        :bare_path,
        :hooks_path,
        :zip_path,
        :clone_path
      ]
      
      for path in object_paths
        @course.send(path).should match /^\//
      end
    end
  end

end

