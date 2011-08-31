require 'spec_helper'

describe CourseRefresher do
  include GitTestActions

  let(:remote_repo_path) { "#{@test_tmp_dir}/fake_remote_repo" }
  let(:remote_repo_url) { "file://#{remote_repo_path}" }
  
  let!(:course) { Course.create!(:name => 'TestCourse', :remote_repo_url => remote_repo_url) }
  
  before :each do
    create_bare_repo(remote_repo_path)
  end
  
  let(:local_clone) { clone_course_repo(course) }
  
  let(:refresher) { CourseRefresher.new }
  
  it "should discover new exercises" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)
    course.exercises.should have(1).item
    course.exercises[0].name.should == 'MyExercise'
  end
  
  it "should discover new exercises in subdirectories" do
    add_exercise('MyCategory/MyExercise')
    add_exercise('MyCategory/MySubcategory/MyExercise')
    refresher.refresh_course(course)
    course.exercises.should have(2).items
    names = course.exercises.map &:name
    names.should include('MyCategory-MyExercise')
    names.should include('MyCategory-MySubcategory-MyExercise')
  end
  
  it "should reload course metadata" do
    course.hide_after.should be_nil

    change_course_metadata_file 'hide_after' => "2011-07-01 13:00"
    refresher.refresh_course(course)
    course.hide_after.should == Time.parse("2011-07-01 13:00") # local time zone

    change_course_metadata_file 'hide_after' => nil
    refresher.refresh_course(course)
    course.hide_after.should == nil

    change_course_metadata_file 'hidden' => true
    refresher.refresh_course(course)
    course.should be_hidden
  end
  
  it "should fail if the course metadata file cannot be parsed" do
    change_course_metadata_file('xooxer', :raw => true)

    expect { refresher.refresh_course(course) }.to raise_error
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

    refresher.refresh_course(course)

    course.exercises.first.deadline.should == Time.parse("2012-01-02 12:34")
    course.exercises.first.gdocs_sheet.should == "xoo"
  end
  
  it "should load changed exercise metadata" do
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
    refresher.refresh_course(course)

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
    refresher.refresh_course(course)

    course.exercises.first.deadline.should == Time.parse("2013-01-01 00:00")
    course.exercises.first.gdocs_sheet.should == "foo"
  end
  
  it "should delete removed exercises from the database" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)

    delete_exercise('MyExercise')
    refresher.refresh_course(course)

    course.exercises.should have(0).items
  end
  
  it "should restore exercises that are removed and subsequently readded" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)

    delete_exercise('MyExercise')
    refresher.refresh_course(course)

    add_exercise('MyExercise')
    refresher.refresh_course(course)

    course.exercises.should have(1).items
  end
  
  it "should cope with exercises that use Java packages" do
    add_exercise('MyExercise', :fixture_name => 'ExerciseWithPackages')
    refresher.refresh_course(course)
    
    course.exercises.should have(1).items
    exercise = course.exercises.first
    exercise.name.should == 'MyExercise'
    exercise.available_points.map(&:name).should include('packagedtest')
  end
  
  it "should scan the exercises for available points" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)
    
    points = course.exercises.where(:name => 'MyExercise').first.available_points
    points.map(&:name).should include('addsub')
  end
  
  it "should delete previously available points that are no longer available" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)
    delete_exercise('MyExercise')
    refresher.refresh_course(course)
    
    AvailablePoint.all.should be_empty
  end
  
  it "should never delete awarded points" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)
    
    exercise = course.exercises.first
    sub = Factory.create(:submission, :course => course, :exercise_name => exercise.name)
    awarded_point = AwardedPoint.create!({
      :course => course,
      :user => sub.user,
      :submission => sub,
      :name => AvailablePoint.first.name
    })
    
    delete_exercise('MyExercise')
    refresher.refresh_course(course)
    
    AwardedPoint.all.should include(awarded_point)
  end
  
  it "should generate exercise zip files" do
    add_exercise('MyExercise')
    add_exercise('MyCategory/MyExercise')

    refresher.refresh_course(course)

    File.should exist(course.zip_path + '/MyExercise.zip')
    File.should exist(course.zip_path + '/MyCategory-MyExercise.zip')
  end
  
  it "should not include hidden tests in the zips" do
    add_exercise('MyExercise')
    refresher.refresh_course(course)
    
    sh!('unzip', course.zip_path + '/MyExercise.zip')
    File.should exist('MyExercise/test/SimpleTest.java')
    File.should_not exist('MyExercise/test/SimpleHiddenTest.java')
  end
  
  it "should delete zip files of removed exercises" do
    add_exercise('MyCategory/MyExercise')
    refresher.refresh_course(course)

    File.should exist(course.zip_path + '/MyCategory-MyExercise.zip')

    FileUtils.rm_rf "#{local_clone.path}/MyCategory/MyExercise"
    local_clone.add_commit_push
    refresher.refresh_course(course)

    File.should_not exist(course.zip_path + '/MyCategory-MyExercise.zip')
  end
  
  it "should delete the old cache directory" do
    old_path = course.cache_path
    refresher.refresh_course(course)
    new_path = course.cache_path
    
    new_path.should_not == old_path
    File.should exist(new_path)
    File.should_not exist(old_path)
  end

  it "should overwrite the new cache directory if it happens to exist" do
    expected_path = course.cache_path.gsub('0', '1')
    FileUtils.mkdir_p(expected_path)
    FileUtils.touch(expected_path + '/foo.txt')
    
    refresher.refresh_course(course)
    
    course.cache_path.should == expected_path
    File.should_not exist(expected_path + '/foo.txt')
  end
  
  describe "on failure" do
    def cause_failure 
      change_course_metadata_file('xooxer', :raw => true)
    end
    
    it "should not leave the new cache directory lying around after a failure" do
      cause_failure
      expect { refresher.refresh_course(course) }.to raise_error
      
      File.should_not exist(course.cache_path)
    end
    
    it "should not delete the old cache directory after a failure" do
      refresher.refresh_course(course)
      old_path = course.cache_path
      cause_failure
      expect { refresher.refresh_course(course) }.to raise_error
      
      File.should exist(old_path)
    end
  end


  def add_exercise(dest_name, options = {})
    options = {
      :commit => true,
      :fixture_name => 'SimpleExercise'
    }.merge options
    local_clone.copy_fixture_exercise(options[:fixture_name], dest_name)
    local_clone.add_commit_push if options[:commit]
  end
  
  def delete_exercise(name)
    FileUtils.rm_rf "#{local_clone.path}/MyExercise"
    local_clone.add_commit_push
  end

  def change_course_metadata_file(data, options = {})
    change_metadata_file('course_options.yml', data, options)
  end

  def change_metadata_file(filename, data, options = {})
    options = { :raw => false, :commit => true }.merge options
    Dir.chdir local_clone.path do
      data = YAML.dump(data) unless options[:raw]
      File.open(filename, 'wb') {|f| f.write(data) }
      local_clone.add_commit_push if options[:commit]
    end
  end

end

