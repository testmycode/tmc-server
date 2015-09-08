require 'spec_helper'

describe CourseRefresher do
  include GitTestActions

  before :each do
    @user = FactoryGirl.create(:user)

    repo_path = "#{@test_tmp_dir}/fake_remote_repo"
    @repo_url = "file://#{repo_path}"
    create_bare_repo(repo_path)

    @template = FactoryGirl.create :course_template, name: 'Template', source_url: @repo_url
    @course = FactoryGirl.create :course, name: 'TestCourse', title: 'TestCourse', source_backend: 'git', course_template: @template, source_url: @repo_url
    @course2 = FactoryGirl.create :course, name: 'TestCourse2', title: 'TestCourse2', source_backend: 'git', course_template: @template, source_url: @repo_url

    @local_clone = clone_course_repo(@course)

    @refresher = CourseRefresher.new
  end

  it 'should discover new exercises' do
    add_exercise('MyExercise')
    refresh_courses
    expect(@course.exercises.size).to eq(1)
    expect(@course.exercises[0].name).to eq('MyExercise')
    expect(@course2.exercises.size).to eq(1)
    expect(@course2.exercises[0].name).to eq('MyExercise')
  end

  # test that git branch is changed for all courses of the same template
  it 'clones the given git branch' do
    @local_clone.chdir do
      system!('git checkout -b foo >/dev/null 2>&1')
    end
    @local_clone.active_branch = 'foo'
    add_exercise('MyExercise')

    @template.git_branch = 'foo'
    @template.save!
    @course.git_branch = 'foo'
    @course.save!

    @refresher.refresh_course @course
    expect(@course.exercises.size).to eq(1)
    expect(@course.exercises[0].name).to eq('MyExercise')
  end

  it 'should discover new exercises in subdirectories' do
    add_exercise('MyCategory/MyExercise')
    add_exercise('MyCategory/MySubcategory/MyExercise')
    refresh_courses
    expect(@course.exercises.size).to eq(2)
    expect(@course2.exercises.size).to eq(2)
    names = @course.exercises.map &:name
    expect(names).to include('MyCategory-MyExercise')
    expect(names).to include('MyCategory-MySubcategory-MyExercise')
    names = @course2.exercises.map &:name
    expect(names).to include('MyCategory-MyExercise')
    expect(names).to include('MyCategory-MySubcategory-MyExercise')
  end

  it 'should allow duplicate available point names for different exercises' do
    add_exercise('MyCategory/MyExercise')
    refresh_courses
    add_exercise('MyCategory/MySubcategory/MyExercise')
    refresh_courses
    expect(@course.exercises.size).to eq(2)
    expect(@course2.exercises.size).to eq(2)
    names = @course.exercises.map &:name
    expect(names).to include('MyCategory-MyExercise')
    expect(names).to include('MyCategory-MySubcategory-MyExercise')
    names = @course2.exercises.map &:name
    expect(names).to include('MyCategory-MyExercise')
    expect(names).to include('MyCategory-MySubcategory-MyExercise')

    points0 = @course.exercises[0].available_points.length
    points1 = @course.exercises[1].available_points.length
    expect(points0).not_to eq(0)
    expect(points1).not_to eq(0)
    expect(points0).to eq(points1)
    points0 = @course2.exercises[0].available_points.length
    points1 = @course2.exercises[1].available_points.length
    expect(points0).not_to eq(0)
    expect(points1).not_to eq(0)
    expect(points0).to eq(points1)

    uniq_points = @course.available_points.map(&:name).uniq.length
    expect(uniq_points).to eq(points0)
    expect(uniq_points).to eq(points1)
    uniq_points = @course2.available_points.map(&:name).uniq.length
    expect(uniq_points).to eq(points0)
    expect(uniq_points).to eq(points1)
  end

  it 'should reload course options' do
    expect(@course.hide_after).to be_nil
    expect(@course2.hide_after).to be_nil

    change_course_options_file 'hide_after' => '2011-07-01 13:00'
    refresh_courses
    expect(@course.hide_after).to eq(Time.zone.parse('2011-07-01 13:00')) # local time zone
    expect(@course2.hide_after).to eq(Time.zone.parse('2011-07-01 13:00')) # local time zone

    change_course_options_file 'hide_after' => nil
    refresh_courses
    expect(@course.hide_after).to eq(nil)
    expect(@course2.hide_after).to eq(nil)

    change_course_options_file 'hidden' => true
    refresh_courses
    expect(@course).to be_hidden
    expect(@course2).to be_hidden

    change_course_options_file 'spreadsheet_key' => 'qwerty'
    refresh_courses
    expect(@course.spreadsheet_key).to eq('qwerty')
    expect(@course2.spreadsheet_key).to eq('qwerty')
  end

  it 'should work with an empty course options file' do
    change_course_options_file '', raw: true
    refresh_courses
    expect(@course.hide_after).to eq(nil)
    expect(@course2.hide_after).to eq(nil)

    change_course_options_file '---', raw: true
    refresh_courses
    expect(@course.hide_after).to eq(nil)
    expect(@course2.hide_after).to eq(nil)
  end

  it 'should load exercise metadata with defaults from superdirs' do
    add_exercise('MyExercise', commit: false)
    change_metadata_file(
      'metadata.yml',
      { 'deadline' => '2000-01-01 00:00', 'gdocs_sheet' => 'xoo' },
      commit: false
    )
    change_metadata_file(
      'MyExercise/metadata.yml',
      { 'deadline' => '2012-01-02 12:34' },
      commit: true
    )

    refresh_courses

    expect(@course.exercises.first.deadline_for(@user)).to eq(Time.zone.parse('2012-01-02 12:34'))
    expect(@course.exercises.first.gdocs_sheet).to eq('xoo')
    expect(@course2.exercises.first.deadline_for(@user)).to eq(Time.zone.parse('2012-01-02 12:34'))
    expect(@course2.exercises.first.gdocs_sheet).to eq('xoo')
  end

  it 'should load changed exercise metadata except for fields defined in UI' do
    add_exercise('MyExercise', commit: false)
    change_metadata_file(
      'metadata.yml',
      { 'deadline' => '2000-01-01 00:00', 'gdocs_sheet' => 'xoo' },
      commit: false
    )
    change_metadata_file('MyExercise/metadata.yml',
                         { 'deadline' => '2012-01-02 12:34' },
                         commit: true
    )
    refresh_courses

    # set soft dl
    expect(ActiveSupport::JSON.decode(@course.exercises.first.soft_deadline_spec)).to be_empty
    ex = @course.exercises.first
    ex.soft_deadline_spec = "[\"02.01.2012 12:33\",\"\"]"
    ex.save!
    expect(@course.exercises.first.soft_deadline_for(@user)).to eq(Time.zone.parse('2012-01-02 12:33'))


    change_metadata_file(
      'metadata.yml',
      { 'deadline' => '2013-01-01 00:00', 'gdocs_sheet' => 'xoo' },
      commit: false
    )
    change_metadata_file(
      'MyExercise/metadata.yml',
      { 'gdocs_sheet' => 'foo' },
      commit: true
    )
    refresh_courses
    expect(@course.exercises.first.soft_deadline_for(@user)).to eq(Time.zone.parse('2012-01-02 12:33'))
    expect(@course.exercises.first.deadline_for(@user)).to eq(Time.zone.parse('2012-01-02 12:34'))
    expect(@course.exercises.first.gdocs_sheet).to eq('foo')
    expect(@course2.exercises.first.deadline_for(@user)).to eq(Time.zone.parse('2012-01-02 12:34'))
    expect(@course2.exercises.first.gdocs_sheet).to eq('foo')
  end

  it 'should allow course-specific overrides in course options' do
    expect(@course.hide_after).to be_nil

    change_course_options_file('hide_after' => '2001-01-01 00:00',
                               'courses' => {
                                 @course.name => {
                                   'hide_after' => '2002-01-01 00:00'
                                 },
                                 'other-course' => {
                                   'hide_after' => '2003-01-01 00:00'
                                 }
                               })
    @refresher.refresh_course @course

    expect(@course.hide_after).to eq(Time.zone.parse('2002-01-01 00:00'))
  end

  it 'should allow course-specific overrides in metadata settings' do
    add_exercise('MyExercise', commit: false)
    change_metadata_file(
      'metadata.yml',
      {
        'deadline' => '2001-01-01 00:00',
        'courses' => {
          @course.name => {
            'deadline' => '2002-01-01 00:00'
          },
          'other-course' => {
            'deadline' => '2003-01-01 00:00'
          }
        }
      },
      commit: true
    )
    @refresher.refresh_course @course

    expect(@course.exercises.first.deadline_for(@user)).to eq(Time.zone.parse('2002-01-01 00:00'))
  end

  it 'should apply course-specific overrides before merging subdirectory settings' do
    add_exercise('MyExercise', commit: false)
    change_metadata_file(
      'metadata.yml',
      {
        'deadline' => '2002-01-01 00:00',
        'courses' => {
          @course.name => {
            'deadline' => '2003-01-01 00:00'
          }
        }
      },
      commit: false
    )
    change_metadata_file(
      'MyExercise/metadata.yml',
      { 'deadline' => '2001-01-01 00:00' },
      commit: true
    )
    @refresher.refresh_course @course

    expect(@course.exercises.first.deadline_for(@user)).to eq(Time.zone.parse('2001-01-01 00:00'))
  end

  it 'should allow overriding a setting with a course-specific nil setting' do
    add_exercise('MyExercise', commit: false)
    change_metadata_file(
      'MyExercise/metadata.yml',
      {
        'deadline' => '2002-01-01 00:00',
        'courses' => {
          @course.name => {
            'deadline' => nil
          }
        }
      },
      commit: true
    )
    @refresher.refresh_course @course

    expect(@course.exercises.first.deadline_for(@user)).to be_nil
  end

  it 'should allow overriding a setting with a nil setting in a subdirectory' do
    add_exercise('MyExercise', commit: false)
    change_metadata_file(
      'metadata.yml',
      { 'deadline' => '2001-01-01 00:00' },
      commit: false
    )
    change_metadata_file(
      'MyExercise/metadata.yml',
      { 'deadline' => nil },
      commit: true
    )
    refresh_courses

    expect(@course.exercises.first.deadline_for(@user)).to be_nil
    expect(@course2.exercises.first.deadline_for(@user)).to be_nil
  end

  it 'should delete removed exercises from the database' do
    add_exercise('MyExercise')
    refresh_courses

    delete_exercise('MyExercise')
    refresh_courses

    expect(@course.exercises.size).to eq(0)
    expect(@course2.exercises.size).to eq(0)
  end

  it 'should mark available points requiring review' do
    add_exercise('MyExercise')
    change_metadata_file(
      'metadata.yml',
      { 'review_points' => 'addsub reviewonly' },
      commit: true
    )
    refresh_courses

    expect(@course.available_points.find_by_name('addsub')).to require_review
    expect(@course.available_points.find_by_name('reviewonly')).not_to be_nil
    expect(@course.available_points.find_by_name('reviewonly')).to require_review
    expect(@course.available_points.find_by_name('mul')).not_to require_review
    expect(@course2.available_points.find_by_name('addsub')).to require_review
    expect(@course2.available_points.find_by_name('reviewonly')).not_to be_nil
    expect(@course2.available_points.find_by_name('reviewonly')).to require_review
    expect(@course2.available_points.find_by_name('mul')).not_to require_review
  end

  it "should change available points' requiring review state after second refresh" do
    add_exercise('MyExercise')
    change_metadata_file(
      'metadata.yml',
      { 'review_points' => 'addsub reviewonly' },
      commit: true
    )
    refresh_courses
    change_metadata_file(
      'metadata.yml',
      { 'review_points' => 'mul' },
      commit: true
    )
    refresh_courses

    expect(@course.available_points.find_by_name('addsub')).not_to require_review
    expect(@course.available_points.find_by_name('reviewonly')).to be_nil
    expect(@course.available_points.find_by_name('mul')).to require_review
    expect(@course2.available_points.find_by_name('addsub')).not_to require_review
    expect(@course2.available_points.find_by_name('reviewonly')).to be_nil
    expect(@course2.available_points.find_by_name('mul')).to require_review
  end

  it 'should ignore exercises under directories with a .tmcignore file' do
    add_exercise('MyExercise')
    refresh_courses

    FileUtils.touch("#{@local_clone.path}/MyExercise/.tmcignore")
    @local_clone.add_commit_push
    refresh_courses

    expect(@course.exercises.size).to eq(0)
    expect(@course2.exercises.size).to eq(0)
  end

  it 'should restore exercises that are removed and subsequently readded' do
    add_exercise('MyExercise')
    refresh_courses

    delete_exercise('MyExercise')
    refresh_courses

    add_exercise('MyExercise')
    refresh_courses

    expect(@course.exercises.size).to eq(1)
    expect(@course2.exercises.size).to eq(1)
  end

  it 'should cope with exercises that use Java packages' do
    add_exercise('MyExercise', fixture_name: 'ExerciseWithPackages')
    refresh_courses

    expect(@course.exercises.size).to eq(1)
    expect(@course2.exercises.size).to eq(1)
    exercise = @course.exercises.first
    expect(exercise.name).to eq('MyExercise')
    expect(exercise.available_points.map(&:name)).to include('packagedtest')
    exercise = @course2.exercises.first
    expect(exercise.name).to eq('MyExercise')
    expect(exercise.available_points.map(&:name)).to include('packagedtest')
  end

  it 'should scan the exercises for available points' do
    add_exercise('MyExercise')
    refresh_courses

    points = @course.exercises.where(name: 'MyExercise').first.available_points
    expect(points.map(&:name)).to include('addsub')
    points = @course2.exercises.where(name: 'MyExercise').first.available_points
    expect(points.map(&:name)).to include('addsub')
  end

  it 'should delete previously available points that are no longer available' do
    add_exercise('MyExercise')
    refresh_courses
    delete_exercise('MyExercise')
    refresh_courses

    expect(AvailablePoint.all).to be_empty
  end

  it 'should never delete awarded points' do
    add_exercise('MyExercise')
    refresh_courses

    exercise = @course.exercises.first
    sub = FactoryGirl.create(:submission, course: @course, exercise_name: exercise.name)
    awarded_point = AwardedPoint.create!(course: @course,
                                         user: sub.user,
                                         submission: sub,
                                         name: AvailablePoint.first.name)

    delete_exercise('MyExercise')
    refresh_courses

    expect(AwardedPoint.all).to include(awarded_point)
  end

  it 'should generate stub versions of exercises' do
    # Tested more thoroughly in lib/course_@refresher/exercise_file_filter_spec.rb
    add_exercise('MyExercise')

    refresh_courses

    stub = Exercise.find_by_name('MyExercise').stub_path

    simple_stuff = File.read(stub + '/src/SimpleStuff.java')
    expect(simple_stuff).not_to include('return a + b;')
    expect(simple_stuff).to include('return 0;')
    expect(simple_stuff).not_to include('STUB:')

    expect(File).not_to exist(stub + '/test/SimpleHiddenTest.java')

    # Should have tmc-junit-runner.jar and its dependencies
    expect(File).to exist(stub + '/lib/testrunner/tmc-junit-runner.jar')
    expect((Dir.new(stub + '/lib/testrunner').entries - ['.', '..']).size).to eq(1 + TmcJunitRunner.get.lib_paths.size)
  end

  it 'should generate solution versions of exercises' do
    # Tested more thoroughly in lib/course_@refresher/exercise_file_filter_spec.rb
    add_exercise('MyExercise')

    refresh_courses

    solution = Exercise.find_by_name('MyExercise').solution_path

    simple_stuff = File.read(solution + '/src/SimpleStuff.java')
    expect(simple_stuff).to include('return a + b;')
    expect(simple_stuff).not_to include('BEGIN SOLUTION')
    expect(simple_stuff).not_to include('return 0;')

    expect(File).not_to exist(solution + '/test/SimpleHiddenTest.java')
  end

  it 'should regenerate changed solutions' do
    add_exercise('MyExercise')
    refresh_courses

    @local_clone.chdir do
      new_file = File.read('MyExercise/src/SimpleStuff.java').gsub('return a + b;', 'return b + a;')
      File.open('MyExercise/src/SimpleStuff.java', 'wb') { |f| f.write(new_file) }
    end
    @local_clone.add_commit_push

    refresh_courses

    solution = Exercise.find_by_name('MyExercise').solution_path
    simple_stuff = File.read(solution + '/src/SimpleStuff.java')
    expect(simple_stuff).to include('return b + a;')
  end

  it 'should generate zips from the stubs' do
    add_exercise('MyExercise')
    add_exercise('MyCategory/MyExercise')

    refresh_courses

    expect(File).to exist(@course.stub_zip_path + '/MyExercise.zip')
    expect(File).to exist(@course.stub_zip_path + '/MyCategory-MyExercise.zip')
    expect(@course.stub_zip_path).to eq(@course2.stub_zip_path)
  end

  it 'should not include hidden tests in the zips' do
    add_exercise('MyExercise')
    refresh_courses

    sh!('unzip', @course.stub_zip_path + '/MyExercise.zip')
    expect(File).not_to exist('MyExercise/test/SimpleHiddenTest.java')
    expect(File).to exist('MyExercise/test/SimpleTest.java')
  end

  it 'should not include metadata files in the zips' do
    local_repo = add_exercise('MyExercise')
    local_repo.write_file('MyExercise/metadata.yml', 'foo: bar')
    local_repo.write_file('MyExercise/non-metadata.yml', 'foo: bar')
    local_repo.add_commit_push
    refresh_courses

    sh!('unzip', @course.stub_zip_path + '/MyExercise.zip')
    expect(File).not_to exist('MyExercise/metadata.yml')
    expect(File).to exist('MyExercise/non-metadata.yml')
  end

  it 'should not remake zip files of removed exercises' do
    add_exercise('MyCategory/MyExercise')
    refresh_courses

    expect(File).to exist(@course.stub_zip_path + '/MyCategory-MyExercise.zip')

    FileUtils.rm_rf "#{@local_clone.path}/MyCategory/MyExercise"
    @local_clone.add_commit_push
    refresh_courses

    expect(File).not_to exist(@course.stub_zip_path + '/MyCategory-MyExercise.zip')
  end

  it 'should generate solution zips' do
    add_exercise('MyExercise')
    add_exercise('MyCategory/MyExercise')

    refresh_courses

    expect(File).to exist(@course.solution_zip_path + '/MyExercise.zip')
    expect(File).to exist(@course.solution_zip_path + '/MyCategory-MyExercise.zip')
  end

  it 'should delete the old cache directory' do
    expect(@course.cache_path).to eq(@course2.cache_path)
    old_path = @course.cache_path
    refresh_courses
    expect(@course.cache_path).to eq(@course2.cache_path)
    new_path = @course.cache_path

    expect(new_path).not_to eq(old_path)
    expect(File).to exist(new_path)
    expect(File).not_to exist(old_path)
  end

  it 'should overwrite the new cache directory if it happens to exist' do
    expected_path = @course.cache_path.gsub('0', '1')
    FileUtils.mkdir_p(expected_path)
    FileUtils.touch(expected_path + '/foo.txt')

    refresh_courses

    expect(@course.cache_path).to eq(expected_path)
    expect(File).not_to exist(expected_path + '/foo.txt')
  end

  it "should store the checksum of each exercise's files in the database" do
    local_repo = add_exercise('MyExercise')
    local_repo.write_file('MyExercise/foo.txt', 'something')
    local_repo.add_commit_push

    refresh_courses
    cs1 = @course.exercises.first.checksum
    cs2 = @course2.exercises.first.checksum

    local_repo.write_file('MyExercise/foo.txt', 'something else')
    local_repo.add_commit_push
    local_repo.write_file('MyExercise/foo.txt', 'something')
    local_repo.add_commit_push

    refresh_courses
    cs3 = @course.exercises.first.checksum
    cs4 = @course2.exercises.first.checksum

    local_repo.write_file('MyExercise/foo.txt', 'something else')
    local_repo.add_commit_push
    refresh_courses
    cs5 = @course.exercises.first.checksum
    cs6 = @course2.exercises.first.checksum

    [cs1, cs2, cs3, cs4, cs5, cs6].each { |cs| expect(cs).not_to be_blank }
    expect(cs1).to eq(cs3) # Only file contents should be checksummed, not metadata
    expect(cs3).not_to eq(cs5)
    expect(cs2).to eq(cs4)
    expect(cs4).not_to eq(cs6)
    expect(cs1).to eq(cs2)
    expect(cs3).to eq(cs4)
    expect(cs5).to eq(cs6)
  end

  it 'should be able to scan maven exercises' # TODO

  it 'should not allow dashes in exercise folders' do
    add_exercise('My-Exercise')

    expect { refresh_courses }.to raise_error(CourseRefresher::Failure)
  end

  it 'should not allow dashes in exercise categories' do
    add_exercise('My-Category/MyExercise')

    expect { refresh_courses }.to raise_error(CourseRefresher::Failure)
  end

  it 'should allow dashes in exercise subfolders' do
    local_repo = add_exercise('MyExercise')
    local_repo.mkdir('MyExercise/my-dir')
    local_repo.write_file('MyExercise/my-dir/foo.txt', 'something')
    local_repo.add_commit_push

    report = @refresher.refresh_course @course
    expect(report.errors).to be_empty
    expect(report.warnings).to be_empty
  end

  it 'should report YAML parsing errors normally' do
    change_course_options_file "foo: bar\noops :error", raw: true
    expect { refresh_courses }.to raise_error(CourseRefresher::Failure)
  end

  describe 'when done twice' do
    it 'should be able to use a different repo' do
      course = FactoryGirl.create :course, source_url: @repo_url
      @refresher.refresh_course course

      repo_path = "#{@test_tmp_dir}/another_fake_remote_repo"
      course.source_url = "file://#{repo_path}"
      create_bare_repo(repo_path)
      course.save!
      @local_clone = clone_course_repo(course)

      add_exercise('NewEx')
      @refresher.refresh_course course

      expect(course.exercises.size).to eq(1)
      expect(course.exercises.first.name).to eq('NewEx')
    end

    it 'should be able to use a different repo for templated courses' #do
    ##
    #  refresh_courses

    #  repo_path = "#{@test_tmp_dir}/another_fake_remote_repo"
    #  create_bare_repo(repo_path)
    #  @template.source_url = "file://#{repo_path}"
    #  @template.save!
    #  @local_clone = clone_course_repo(@course)

    #  add_exercise('NewEx')
    #  refresh_courses

    #  expect(@course.exercises.size).to eq(1)
    #  expect(@course.exercises.first.name).to eq('NewEx')
    #  expect(@course2.exercises.size).to eq(1)
    #  expect(@course2.exercises.first.name).to eq('NewEx')
    #end
  end

  describe 'on failure' do
    def sabotage
      expect(CourseRefresher).to receive(:simulate_failure!).and_raise('simulated failure')
    end

    it 'should not leave the new cache directory lying around' do
      sabotage
      expect { refresh_courses }.to raise_error

      expect(File).not_to exist(@template.cache_path)
      expect(File).not_to exist(@course.cache_path)
      expect(File).not_to exist(@course2.cache_path)
    end

    it 'should not delete the old cache directory' do
      refresh_courses
      old_path = @course.cache_path
      sabotage
      expect { refresh_courses }.to raise_error

      expect(File).to exist(old_path)
    end

    it 'should roll back any database changes' do
      old_cache_version = @course.cache_version
      old_exercises = Exercise.order(:id).to_a
      old_points = AvailablePoint.order(:id).to_a

      sabotage
      expect { refresh_courses }.to raise_error

      @template.reload
      expect(@template.cache_version).to eq(old_cache_version)
      @course.reload
      expect(@course.cache_version).to eq(old_cache_version)
      @course2.reload
      expect(@course2.cache_version).to eq(old_cache_version)
      expect(Exercise.order(:id).to_a).to eq(old_exercises)
      expect(AvailablePoint.order(:id).to_a).to eq(old_points)
    end
  end

  describe 'for MakefileC exercises' do
    it 'should scan the exercises for available points' do
      add_exercise('MakefileC', fixture_name: 'MakefileC')
      refresh_courses

      points = @course.exercises.where(name: 'MakefileC').first.available_points
      expect(points.map(&:name)).to include('point1')
      points = @course2.exercises.where(name: 'MakefileC').first.available_points
      expect(points.map(&:name)).to include('point1')
    end

    it 'should delete previously available points that are no longer available' do
      add_exercise('MakefileC', fixture_name: 'MakefileC')
      refresh_courses
      delete_exercise('MakefileC')
      refresh_courses

      expect(AvailablePoint.all).to be_empty
    end
  end

  describe 'with no_directory_changes flag' do
    it 'doesn\'t increment cache_version' do
      refresh_courses
      expect(@template.cache_version).not_to eq(2)
      expect(@course.cache_version).not_to eq(2)
      expect(@course2.cache_version).not_to eq(2)
      expect(@template.cache_version).to eq(1)
      expect(@course.cache_version).to eq(1)
      expect(@course2.cache_version).to eq(1)
    end

    it 'doesn\'t create duplicate repository folder' do
      refresh_courses
      expect(Dir["#{@test_tmp_dir}/cache/git_repos/*"].count).to be(1)
    end

    it 'doesn\'t remove any folders on fail' do
      @refresher.refresh_course(@course)
      @template.reload

      expect(CourseRefresher).to receive(:simulate_failure!).and_raise('simulated failure')
      expect{ @refresher.refresh_course(@course2, no_directory_changes: true) }.to raise_error

      expect(File).to exist(@template.cache_path)
      expect(File).to exist(@course.cache_path)
      expect(File).to exist(@course2.cache_path)
      expect(Dir["#{@test_tmp_dir}/cache/git_repos/*"].count).to be(1)
    end
  end

  def add_exercise(dest_name, options = {})
    options = {
      commit: true,
      fixture_name: options[:fixture_name] || 'SimpleExerciseWithSolutionsAndStubs'
    }.merge options
    @local_clone.copy_fixture_exercise(options[:fixture_name], dest_name)
    @local_clone.add_commit_push if options[:commit]
    @local_clone
  end

  def delete_exercise(name)
    FileUtils.rm_rf "#{@local_clone.path}/#{name}"
    @local_clone.add_commit_push
  end

  def change_course_options_file(data, options = {})
    change_metadata_file('course_options.yml', data, options)
  end

  def change_metadata_file(filename, data, options = {})
    options = { raw: false, commit: true }.merge options
    Dir.chdir @local_clone.path do
      data = YAML.dump(data) unless options[:raw]
      File.open(filename, 'wb') { |f| f.write(data) }
      @local_clone.add_commit_push if options[:commit]
    end
  end

  def refresh_courses
    @refresher.refresh_course(@course)
    @refresher.refresh_course(@course2, no_directory_changes: true)
    @template.reload
  end
end
