require 'spec_helper'
require 'tmpdir'
require 'shellwords'
require 'system_commands'

describe SubmissionPackager do
  include GitTestActions
  include SystemCommands
  
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
  
  describe "tmc-run script added to the archive" do
    it "should compile and run the submission" do
      @exercise_project.solve_all
      @exercise_project.make_zip(:src_only => false)
      
      SubmissionPackager.new.package_submission(@exercise, @exercise_project.zip_path, @tar_path)
      
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          sh! ['tar', 'xf', @tar_path]
          File.should_not exist('classes/main/SimpleStuff.class')
          File.should_not exist('output.txt')
          sh! ['./tmc-run']
          File.should exist('classes/main/SimpleStuff.class')
          File.should exist('output.txt')
        end
      end
    end
    
    it "should report compilation errors in output.txt with exit code 101" do
      @exercise_project.introduce_compilation_error
      @exercise_project.make_zip(:src_only => false)
      
      SubmissionPackager.new.package_submission(@exercise, @exercise_project.zip_path, @tar_path)
      
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          sh! ['tar', 'xf', @tar_path]
          File.should_not exist('classes/main/SimpleStuff.class')
          File.should_not exist('output.txt')
          `./tmc-run`
          $?.exitstatus.should == 101
          File.should exist('output.txt')
          
          output = File.read('output.txt')
          output.should include('compiler should fail here')
        end
      end
    end
  end
end
