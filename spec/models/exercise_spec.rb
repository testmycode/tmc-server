require 'spec_helper'

describe Exercise do
  include GitTestActions

  describe "when read from a course repo" do
    before :each do
      @course_name = 'MyCourse'
      FileUtils.mkdir_p 'bare_repo'
      copy_model_repo("bare_repo/#{@course_name}")
      system! "git clone -q bare_repo/#{@course_name} #{@course_name}"
      @repo = GitRepo.new(@course_name)
    end
    
    it "should find all exercise names" do
      @repo.copy_simple_exercise('Ex1')
      @repo.copy_simple_exercise('Ex2')
      @repo.add_commit_push
      
      exercise_names = Exercise.read_exercise_names(@course_name)
      exercise_names.length.should == 2
      
      exercise_names.sort!
      exercise_names[0].should == 'Ex1'
      exercise_names[1].should == 'Ex2'
    end
    
    # TODO: should test metadata loading, but tests for Course.refresh already test that.
    # Some more mocking should probably happen somewhere..
    
  end
end

