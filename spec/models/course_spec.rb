require 'spec_helper'

describe Course do

  let(:remote_repo_path) { "#{@test_tmp_dir}/fake_remote_repo" }
  let(:remote_repo_url) { "file://#{remote_repo_path}" }

  it "can be created with just a name parameter" do
    Course.create!(:name => 'TestCourse')
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
  
  
  [:local, :remote].each do |repo_type|
    describe "when refreshed (using #{repo_type} repo)" do
      include GitTestActions
      
      case repo_type
      when :local then
        let!(:course) { Course.create!(:name => 'TestCourse') }
      when :remote then
        let!(:course) { Course.create!(:name => 'TestCourse', :remote_repo_url => remote_repo_url) }
        
        before :each do
          copy_model_repo(remote_repo_path)
        end
      end
      
      let(:local_clone) { clone_course_repo(course) }
      
      it "should discover new exercises" do
        add_exercise('MyExercise')
        course.refresh
        course.exercises.should have(1).item
        course.exercises[0].name.should == 'MyExercise'
      end
      
      it "should discover new exercises in subdirectories" do
        add_exercise('MyCategory/MyExercise')
        add_exercise('MyCategory/MySubcategory/MyExercise')
        course.refresh
        course.exercises.should have(2).items
        names = course.exercises.map &:name
        names.should include('MyCategory-MyExercise')
        names.should include('MyCategory-MySubcategory-MyExercise')
      end
      
      it "should reload course metadata" do
        course.hide_after.should be_nil
        
        change_course_metadata_file 'hide_after' => "2011-07-01 13:00"
        course.refresh
        course.hide_after.should == Time.parse("2011-07-01 13:00") # local time zone
        
        change_course_metadata_file 'hide_after' => nil
        course.refresh
        course.hide_after.should == nil
        
        change_course_metadata_file 'hidden' => true
        course.refresh
        course.should be_hidden
      end
      
      it "should fail if the course metadata file cannot be parsed" do
        change_course_metadata_file('xooxer', :raw => true)
        
        expect { course.refresh }.to raise_error
      end
      
      it "should load exercise metadata with defaults from superdirs" do
        add_exercise('MyExercise', :commit => false)
        change_metadata_file(
          'metadata.yml',
          {'deadline' => "2000-01-01 00:00", 'gdocs_sheet' => 'xoo'},
          {:commit => false}
        )
        change_metadata_file(
          'MyExercise/metadata.yml',
          {'deadline' => "2012-01-02 12:34"},
          {:commit => true}
        )
        
        course.refresh
        
        course.exercises.first.deadline.should == Time.parse("2012-01-02 12:34")
        course.exercises.first.gdocs_sheet.should == "xoo"
      end
      
      it "should reload changed exercise metadata" do
        add_exercise('MyExercise', :commit => false)
        change_metadata_file(
          'metadata.yml',
          {'deadline' => "2000-01-01 00:00", 'gdocs_sheet' => 'xoo'},
          {:commit => false}
        )
        change_metadata_file('MyExercise/metadata.yml',
          {'deadline' => "2012-01-02 12:34"},
          {:commit => true}
        )
        course.refresh
        
        change_metadata_file(
          'metadata.yml',
          {'deadline' => "2013-01-01 00:00", 'gdocs_sheet' => 'xoo'},
          {:commit => false}
        )
        change_metadata_file(
          'MyExercise/metadata.yml',
          {'gdocs_sheet' => "foo"},
          {:commit => true}
        )
        course.refresh
        
        course.exercises.first.deadline.should == Time.parse("2013-01-01 00:00")
        course.exercises.first.gdocs_sheet.should == "foo"
      end
      
      it "should generate exercise zip files" do
        add_exercise('MyExercise')
        add_exercise('MyCategory/MyExercise')
        
        course.refresh

        File.should exist(course.zip_path + '/MyExercise.zip')
        File.should exist(course.zip_path + '/MyCategory-MyExercise.zip')
      end
      
      it "should delete removed exercises from the database" do
        add_exercise('MyExercise')
        course.refresh
        
        FileUtils.rm_rf "#{local_clone.path}/MyExercise"
        local_clone.add_commit_push
        course.refresh
        
        course.exercises.should have(0).items
      end
      
      it "should restore removed and restored exercises in the database" do
        add_exercise('MyExercise')
        course.refresh
        
        FileUtils.rm_rf "#{local_clone.path}/MyExercise"
        local_clone.add_commit_push
        course.refresh
        
        add_exercise('MyExercise')
        course.refresh
        
        course.exercises.should have(1).items
      end
      
      it "should delete zip files of removed exercises" do
        expected_zip_path = course.zip_path + '/MyCategory-MyExercise.zip'
        
        add_exercise('MyCategory/MyExercise')
        course.refresh
        
        File.should exist(expected_zip_path)
        
        FileUtils.rm_rf "#{local_clone.path}/MyCategory/MyExercise"
        local_clone.add_commit_push
        course.refresh
        
        File.should_not exist(expected_zip_path)
      end
    end
  end
  
  def add_exercise(name, options = {})
    options = { :commit => true }.merge options
    local_clone.copy_simple_exercise(name)
    local_clone.add_commit_push if options[:commit]
  end
  
  def change_course_metadata_file(data, options = {})
    change_metadata_file('course_options.yml', data, options)
  end
  
  def change_metadata_file(filename, data, options = {})
    options = { :raw => false, :commit => true }.merge options
    Dir.chdir local_clone.path do
      data = YAML.dump data unless options[:raw]
      File.open(filename, 'wb') {|f| f.write(data) }
      local_clone.add_commit_push if options[:commit]
    end
  end

end
