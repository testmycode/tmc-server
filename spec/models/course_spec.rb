require 'spec_helper'

describe Course do

  it "can be created with just a name parameter" do
    Course.create!(:name => 'TestCourse')
  end

  it "should create a repository when created" do
    repo_path = Course.create!(:name => 'TestCourse').bare_path
    File.exists?(repo_path).should be_true
  end
  
  it "should delete the repository when destroyed" do
    course = Course.create!(:name => 'TestCourse')
    repo_path = course.bare_path
    course.destroy
    File.exists?(repo_path).should be_false
  end

  describe "validations" do
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
  
  describe "when refreshed" do
    include GitTestActions
    
    before :each do
      @course = Course.create!(:name => 'TestCourse')
      @repo = clone_course_repo(@course)
    end
    
    it "should discover new exercises" do
      add_exercise('MyExercise')
      @course.refresh
      @course.exercises.should have(1).items
      @course.exercises[0].name.should == 'MyExercise'
    end
    
    it "should reload course metadata" do
      @course.hide_after.should be_nil
      
      change_course_metadata_file 'hide_after' => "2011-07-01 13:00"
      @course.refresh
      @course.hide_after.should == Time.parse("2011-07-01 13:00") # local time zone
      
      change_course_metadata_file 'hide_after' => "2011-07-01 14:00"
      @course.refresh
      @course.hide_after.should == Time.parse("2011-07-01 14:00")
    end
    
    it "should fail if the course metadata file cannot be parsed" do
      change_course_metadata_file('xooxer', :raw => true)
      
      expect { @course.refresh }.to raise_error
    end
    
    it "should load exercise metadata" do
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
      
      @course.refresh
      
      @course.exercises.first.deadline.should == Time.parse("2012-01-02 12:34")
      @course.exercises.first.gdocs_sheet.should == "xoo"
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
        @course.refresh
        
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
        @course.refresh
        
        @course.exercises.first.deadline.should == Time.parse("2013-01-01 00:00")
        @course.exercises.first.gdocs_sheet.should == "foo"
    end
    
    def add_exercise(name, options = {})
      options = options.merge :commit => true
      @repo.copy_model_exercise(name)
      @repo.add_commit_push if options[:commit]
    end
    
    def change_course_metadata_file(data, options = {})
      change_metadata_file('course_options.yml', data, options)
    end
    
    def change_metadata_file(filename, data, options = {})
      options = options.merge :raw => false, :commit => true
      Dir.chdir @repo.path do
        data = YAML.dump data unless options[:raw]
        File.open(filename, 'wb') {|f| f.write(data) }
        @repo.add_commit_push if options[:commit]
      end
    end
  end

end
