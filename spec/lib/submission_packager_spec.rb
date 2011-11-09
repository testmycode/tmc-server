require 'spec_helper'
require 'tmpdir'
require 'shellwords'

describe SubmissionPackager do
  include GitTestActions
  
    before :each do
      @setup = SubmissionTestSetup.new(:exercise_name => 'SimpleExercise')
      @course = @setup.course
      @repo = @setup.repo
      @exercise_project = @setup.exercise_project
      @exercise = @setup.exercise
      @user = @setup.user
      @submission = @setup.submission
      
      @tar_path = Pathname.new('result.tar').expand_path.to_s
    end

  it "should package the submission in a tar file with tests from the repo" do
    @exercise_project.solve_all
    @exercise_project.make_zip(:src_only => false)
    
    SubmissionPackager.new.package_submission(@exercise, @exercise_project.zip_path, @tar_path)
    
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `tar xf #{Shellwords.escape(@tar_path)}`
        File.should exist('src/SimpleStuff.java')
        File.read('src/SimpleStuff.java').should == File.read(@exercise_project.path + '/src/SimpleStuff.java')
        
        File.should exist('test/SimpleTest.java')
        File.should exist('test/SimpleHiddenTest.java')
      end
    end
  end
  
  it "should not use any tests from the submission" do
    @exercise_project.solve_all
    File.open(@exercise_project.path + '/test/SimpleTest.java', 'w') {|f| f.write('foo') }
    File.open(@exercise_project.path + '/test/NewTest.java', 'w') {|f| f.write('bar') }
    @exercise_project.make_zip(:src_only => false)
    
    SubmissionPackager.new.package_submission(@exercise, @exercise_project.zip_path, @tar_path)
    
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        `tar xf #{Shellwords.escape(@tar_path)}`
        File.read('test/SimpleTest.java').should == File.read(@exercise.fullpath + '/test/SimpleTest.java')
        File.should_not exist('test/NewTest.java')
      end
    end
  end
end
