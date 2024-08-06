# frozen_string_literal: true

require 'spec_helper'
require 'course_refresh_database_updater'

describe CourseRefreshDatabaseUpdater do
  include GitTestActions

  before :each do
    @user = FactoryBot.create(:user)

    repo_path = "#{@test_tmp_dir}/fake_remote_repo"
    @repo_url = "file://#{repo_path}"
    create_bare_repo(repo_path)

    @template = FactoryBot.create :course_template, name: 'Template', source_url: @repo_url
    @course = FactoryBot.create :course, name: 'TestCourse', title: 'TestCourse', source_backend: 'git', course_template: @template, source_url: @repo_url
    @course2 = FactoryBot.create :course, name: 'TestCourse2', title: 'TestCourse2', source_backend: 'git', course_template: @template, source_url: @repo_url

    @local_clone = clone_course_repo(@course)

    # @refresher = CourseRefresher.new
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

    @course.refresh(@user.id)
    RefreshCourseTask.new.run
    # @refresher.refresh_course @course
    expect(@course.exercises.size).to eq(1)
    expect(@course.exercises[0].name).to eq('MyExercise')
  end

  it 'should discover new exercises in subdirectories' do
    add_exercise('MyCategory/MyExercise')
    add_exercise('MyCategory/MySubcategory/MyExercise')
    refresh_courses

    expect(@course.exercises.size).to eq(2)
    expect(@course2.exercises.size).to eq(2)
    names = @course.exercises.map(&:name)
    expect(names).to include('MyCategory-MyExercise')
    expect(names).to include('MyCategory-MySubcategory-MyExercise')
    names = @course2.exercises.map(&:name)
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
    names = @course.exercises.map(&:name)
    expect(names).to include('MyCategory-MyExercise')
    expect(names).to include('MyCategory-MySubcategory-MyExercise')
    names = @course2.exercises.map(&:name)
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

  it 'should allow course-specific overrides in course options' do
    expect(@course.hide_after).to be_nil

    change_course_options_file({ 'hide_after' => '2001-01-01 00:00',
                               'courses' => {
                                  @course.name => {
                                    'hide_after' => '2002-01-01 00:00'
                                  },
                                  'other-course' => {
                                    'hide_after' => '2003-01-01 00:00'
                                  }
                                } })
    @course.refresh(@user.id)
    RefreshCourseTask.new.run
    @course.reload

    expect(@course.hide_after).to eq(Time.zone.parse('2002-01-01 00:00'))
  end

  it 'should delete removed exercises from the database' do
    add_exercise('MyExercise')
    refresh_courses

    delete_exercise('MyExercise')
    refresh_courses

    expect(@course.exercises.size).to eq(0)
    expect(@course2.exercises.size).to eq(0)
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
    sub = FactoryBot.create(:submission, course: @course, exercise_name: exercise.name)
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

    stub = Exercise.find_by(name: 'MyExercise').stub_path

    simple_stuff = File.read(stub + '/src/SimpleStuff.java')
    expect(simple_stuff).not_to include('return a + b;')
    expect(simple_stuff).to include('return 0;')
    expect(simple_stuff).not_to include('STUB:')

    expect(File).not_to exist(stub + '/test/SimpleHiddenTest.java')

    # Should have tmc-junit-runner.jar and its dependencies
    expect(File).to exist(stub + '/lib/testrunner/tmc-junit-runner.jar')
    # TmcJunitRunner is a uber jar
    expect((Dir.new(stub + '/lib/testrunner').entries - ['.', '..']).size).to eq(1)
  end

  it 'should generate solution versions of exercises' do
    # Tested more thoroughly in lib/course_@refresher/exercise_file_filter_spec.rb
    add_exercise('MyExercise')

    refresh_courses

    solution = Exercise.find_by(name: 'MyExercise').solution_path

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

    solution = Exercise.find_by(name: 'MyExercise').solution_path
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
    expected_path = @course.cache_path.tr('0', '1')
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

  it 'should not allow dashes in exercise folders' do
    add_exercise('My-Exercise')
    refresh_courses
    refresh_report = @template.course_template_refreshes.last

    expect(refresh_report.course_template_refresh_phases.last.phase_name).to include("contained a dash '-' which is currently not allowed")
    expect(refresh_report.status).to eq('crashed')
  end

  it 'should not allow dashes in exercise categories' do
    add_exercise('My-Category/MyExercise')
    refresh_courses
    refresh_report = @template.course_template_refreshes.last

    expect(refresh_report.course_template_refresh_phases.last.phase_name).to include("contained a dash '-' which is currently not allowed")
    expect(refresh_report.status).to eq('crashed')
  end

  it 'should allow dashes in exercise subfolders' do
    local_repo = add_exercise('MyExercise')
    local_repo.mkdir('MyExercise/my-dir')
    local_repo.write_file('MyExercise/my-dir/foo.txt', 'something')
    local_repo.add_commit_push

    # report = @refresher.refresh_course @course
    @course.refresh(@user.id)
    RefreshCourseTask.new.run
    report = @course.course_template.course_template_refreshes.last.course_template_refresh_report
    expect(report['refresh_errors']).to be_empty
    expect(report['refresh_warnings']).to be_empty
  end

  it 'should report YAML parsing errors normally' do
    change_course_options_file "foo: bar\noops :error", raw: true
    refresh_courses
    refresh_report = @template.course_template_refreshes.last
    expect(refresh_report.course_template_refresh_phases.last.phase_name).to include('while parsing a block mapping')
    expect(refresh_report.status).to eq('crashed')
  end

  describe 'when done twice' do
    it 'should be able to use a different repo' do
      course = FactoryBot.create :course, source_url: @repo_url
      # @refresher.refresh_course course
      course.refresh(@user.id)
      RefreshCourseTask.new.run

      repo_path = "#{@test_tmp_dir}/another_fake_remote_repo"
      course.source_url = "file://#{repo_path}"
      create_bare_repo(repo_path)
      course.save!
      @local_clone = clone_course_repo(course)

      add_exercise('NewEx')
      # @refresher.refresh_course course
      course.refresh(@user.id)
      RefreshCourseTask.new.run

      expect(course.exercises.size).to eq(1)
      expect(course.exercises.first.name).to eq('NewEx')
    end

    it 'should be able to use a different repo for templated courses' # do
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
    # end
  end

  describe 'on failure' do
    def sabotage
      expect(CourseRefreshDatabaseUpdater).to receive(:simulate_failure!).and_raise('simulated failure')
    end

    it 'should not leave the new cache directory lying around' do
      sabotage
      refresh_courses
      refresh_report = @template.course_template_refreshes.last
      expect(refresh_report.status).to eq('crashed')

      expect(File).not_to exist(@template.cache_path)
      expect(File).not_to exist(@course.cache_path)
      expect(File).not_to exist(@course2.cache_path)
    end

    it 'should not delete the old cache directory' do
      refresh_courses
      old_path = @course.cache_path
      sabotage
      refresh_courses
      refresh_report = @template.course_template_refreshes.last
      expect(refresh_report.status).to eq('crashed')

      expect(File).to exist(old_path)
    end

    it 'should roll back any database changes' do
      old_cached_version = @course.cached_version
      old_exercises = Exercise.order(:id).to_a
      old_points = AvailablePoint.order(:id).to_a

      sabotage
      refresh_courses
      refresh_report = @template.course_template_refreshes.last
      expect(refresh_report.status).to eq('crashed')

      @template.reload
      expect(@template.cached_version).to eq(old_cached_version)
      @course.reload
      expect(@course.cached_version).to eq(old_cached_version)
      @course2.reload
      expect(@course2.cached_version).to eq(old_cached_version)
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
    it "doesn't increment cached_version" do
      refresh_courses
      expect(@template.cached_version).not_to eq(2)
      expect(@course.cached_version).not_to eq(2)
      expect(@course2.cached_version).not_to eq(2)
      expect(@template.cached_version).to eq(1)
      expect(@course.cached_version).to eq(1)
      expect(@course2.cached_version).to eq(1)
    end

    it "doesn't create duplicate repository folder" do
      refresh_courses
      expect(Dir["#{@test_tmp_dir}/cache/git_repos/*"].count).to be(1)
    end

    it "doesn't remove any folders on fail" do
      # @refresher.refresh_course(@course)
      @course.refresh(@user.id)
      RefreshCourseTask.new.run
      @template.reload

      expect(CourseRefreshDatabaseUpdater).to receive(:simulate_failure!).and_raise('simulated failure')
      refresh_courses
      refresh_report = @template.course_template_refreshes.last
      expect(refresh_report.status).to eq('crashed')

      expect(File).to exist(@template.cache_path)
      expect(File).to exist(@course.cache_path)
      expect(File).to exist(@course2.cache_path)
      # Should also have the newly generate tmc-lang-rust folder, if database updating fails
      expect(Dir["#{@test_tmp_dir}/cache/git_repos/*"].count).to be(2)
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
    # Refreshes whole template nowadays if you refresh any course generated from a template
    @course.refresh(@user.id)
    RefreshCourseTask.new.run
    @course.reload
    @course2.reload
    @template.reload
  end
end
