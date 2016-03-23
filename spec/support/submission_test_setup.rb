require File.expand_path(File.join(File.dirname(__FILE__), 'git_test_actions.rb'))

# Aggregates everything needed to test checking a submission
class SubmissionTestSetup
  include GitTestActions

  attr_reader :course
  attr_reader :repo
  attr_reader :exercise
  attr_reader :exercise_project
  attr_reader :user
  attr_reader :submission

  def initialize(options = {})
    options = default_options.merge(options)

    organization = options[:organization] || Organization.create!(name: 'name', information: 'info', slug: 'slug', verified: true)
    course_name = options[:course_name]
    exercise_name = options[:exercise_name] || 'SimpleExercise'
    exercise_dest = options[:exercise_dest] || exercise_name
    should_solve = options[:solve]
    should_save = options[:save]
    @user = options[:user] || create_user

    @test_tmp_dir = "#{::Rails.root}/tmp/tests"
    @repo_path = @test_tmp_dir + '/fake_remote_repo'
    create_bare_repo(@repo_path)

    @course = Course.create!(name: course_name, title: course_name, source_backend: 'git', source_url: @repo_path, organization: organization)
    @repo = clone_course_repo(@course)
    @repo.copy_fixture_exercise(exercise_name, exercise_dest)
    @repo.add_commit_push
    @course.refresh

    @exercise = @course.exercises.first
    unless @exercise
      fail 'Exercise created from fixture was not recognized by course refresher'
    end

    @exercise_project = FixtureExercise.get(exercise_name, exercise_dest)

    @submission = Submission.new(
      user: @user,
      course: @course,
      exercise: @exercise
    )

    if should_solve
      @exercise_project.solve_all
    end

    if should_save
      make_zip
      @submission.save!
    end
  end

  def make_zip(options = {})
    @exercise_project.make_zip(options)
    @submission.return_file = File.read(@exercise_project.zip_path)
    @submission.save!
  end

  def default_options
    {
      course_name: 'MyCourse',
      exercise_name: nil,
      exercise_dest: nil,
      user: nil,
      solve: false,
      save: false
    }
  end

  private

  def create_user
    FactoryGirl.create(:user, login: 'student', password: 'student')
  end
end
