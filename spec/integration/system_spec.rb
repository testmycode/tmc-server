require 'spec_helper'

describe "The system" do
  include IntegrationTestActions
  include SystemCommands

  it "should show the university name on the front page" do
    visit '/'
    page.should have_content('HELSINKI UNIVERSITY')
  end

  describe "(used by an instructor for administration)" do
  
    before :each do
      visit '/'
      @user = User.create!(:login => 'user', :password => 'xooxer', :administrator => true)
      log_in_as(@user.login)
    end
    
    it "should create a local git repo for new courses by default" do
      create_new_course('mycourse')
      bare_repo_path = GitBackend.repositories_root + '/mycourse.git'
      File.should exist(bare_repo_path)
    end
    
    it "should allow using a remote git repo for new courses" do
      copy_model_repo("#{@test_tmp_dir}/fake_remote_repo")
      
      create_new_course('mycourse', :remote_repo_url => "file://#{@test_tmp_dir}/fake_remote_repo")
      
      bare_repo_path = GitBackend.repositories_root + '/mycourse.git'
      File.should_not exist(bare_repo_path)
      
    end
    
    it "should show all exercises pushed to the course's git repo" do
      create_new_course('mycourse')
      course = Course.find_by_name!('mycourse')
      
      repo = clone_course_repo(course)
      repo.copy_simple_exercise('MyExercise', :deadline => (Date.today - 1.day).to_s)
      repo.add_commit_push
      
      manually_refresh_course('mycourse')
      
      visit '/courses'
      click_link 'mycourse'
      page.should have_content('MyExercise')
    end
  end
  
  
  
  describe "(used by a student)" do
    before :each do
      @course = Course.create!(:name => 'mycourse')
      @repo = clone_course_repo(@course)
      @repo.copy_simple_exercise('MyExercise')
      @repo.add_commit_push
      
      @course.refresh
      
      visit '/'
      click_link 'mycourse'
    end
    
    it "should offer exercises as downloadable zips" do
      click_link('zip')
      File.open('MyExercise.zip', 'wb') {|f| f.write(page.source) }
      system!("unzip -qq MyExercise.zip")
      
      File.should be_a_directory('MyExercise')
      File.should be_a_directory('MyExercise/nbproject')
      File.should exist('MyExercise/src/SimpleStuff.java')
    end
    
    it "should show successful test results for correct solutions" do
      ex = SimpleExercise.new('MyExercise')
      ex.solve_all
      ex.make_zip
      
      click_link 'MyExercise'
      fill_in 'Username', :with => '123'
      attach_file('Zipped project', 'MyExercise.zip')
      click_button 'Submit'
      
      page.should have_content('All tests successful')
      page.should have_content('Ok')
      page.should_not have_content('Fail')
    end
    
    it "should show unsuccessful test results for incorrect solutions" do
      ex = SimpleExercise.new('MyExercise')
      ex.make_zip
      
      click_link 'MyExercise'
      fill_in 'Username', :with => '123'
      attach_file('Zipped project', 'MyExercise.zip')
      click_button 'Submit'
      
      page.should have_content('Some tests failed')
      page.should have_content('Fail')
    end
    
    it "should show compilation error for uncompilable solutions" do
      ex = SimpleExercise.new('MyExercise')
      ex.introduce_compilation_error('oops')
      ex.make_zip
      
      click_link 'MyExercise'
      fill_in 'Username', :with => '123'
      attach_file('Zipped project', 'MyExercise.zip')
      click_button 'Submit'
      
      page.should have_content('Compilation error')
      page.should have_content('oops')
    end
    
    it "should not show exercises whose deadline has passed" do
      @repo.set_metadata_in('MyExercise', 'deadline' => Date.yesterday.to_s)
      @repo.add_commit_push
      @course.refresh
      
      visit '/'
      click_link 'mycourse'
      
      page.should_not have_content('MyExercise')
    end
  end
  
  
  
  describe "(used by an instructor for viewing statistics)" do
  
    before :each do
      course = Course.create!(:name => 'mycourse')
      repo = clone_course_repo(course)
      repo.copy_simple_exercise('EasyExercise')
      repo.copy_simple_exercise('HardExercise')
      repo.add_commit_push
      
      course.refresh
    end
    
    it "should show all submissions for an exercise" do
      submit_exercise('EasyExercise', :solve => true, :username => '123')
      submit_exercise('EasyExercise', :solve => false, :username => '456')
      submit_exercise('EasyExercise', :compilation_error => true, :username => '789')
      
      log_in_as_instructor
      click_link 'mycourse' 
      click_link 'EasyExercise'
      
      page.should have_content('123')
      page.should have_content('456')
      page.should have_content('789')
      page.should have_content('Ok')
      page.should have_content('Fail')
      page.should have_content('Error')
    end
    
    def submit_exercise(exercise_name, options = {})
      options = {
        :solve => true,
        :compilation_error => false,
        :username => 'some_username'
      }.merge(options)
      
      FileUtils.rm_rf exercise_name
      ex = SimpleExercise.new(exercise_name)
      ex.solve_all if options[:solve]
      ex.introduce_compilation_error('oops') if options[:compilation_error]
      ex.make_zip
      
      visit '/'
      click_link 'mycourse'
      click_link exercise_name
      fill_in 'Username', :with => options[:username]
      attach_file('Zipped project', "#{exercise_name}.zip")
      click_button 'Submit'
    end
    
    def log_in_as_instructor
      visit '/'
      user = User.create!(:login => 'user', :password => 'xooxer', :administrator => true)
      log_in_as(user.login)
    end
  end
  
  
end
