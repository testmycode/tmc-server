require 'spec_helper'

describe "The system (used by a student)" do
  include IntegrationTestActions
  
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
