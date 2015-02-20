require 'spec_helper'

describe Exercise, type: :model do
  include GitTestActions

  let(:user) { FactoryGirl.create(:user) }
  let(:course) { FactoryGirl.create(:course) }

  describe 'gdocs_sheet' do
    it 'should deduce gdocs_sheet from exercise name' do
      ex1 = FactoryGirl.create(:exercise, name: 'ex')
      ex1.options = {}
      expect(ex1.gdocs_sheet).to eq('root')

      ex2 = FactoryGirl.create(:exercise, name: 'wtf-ex')
      ex2.options = {}
      expect(ex2.gdocs_sheet).to eq('wtf')

      ex3 = FactoryGirl.create(:exercise, name: 'omg-wtf-ex')
      ex3.options = {}
      expect(ex3.gdocs_sheet).to eq('omg-wtf')

      ex4 = FactoryGirl.create(:exercise, name: 'omg-wtf-ex')
      ex4.options = { 'points_visible' => false }
      expect(ex4.gdocs_sheet).to eq(nil)
    end
  end

  describe 'course_gdocs_sheet_exercises scope' do
    it 'should find all the exercises that belong to the gdocs_sheet' do
      sheetname = 'lolwat'
      course = FactoryGirl.create(:course)
      ex1 = FactoryGirl.create(:exercise, course: course,
                                          gdocs_sheet: sheetname)
      ex2 = FactoryGirl.create(:exercise, course: course,
                                          gdocs_sheet: sheetname)
      ex3 = FactoryGirl.create(:exercise, course: course,
                                          gdocs_sheet: "not#{sheetname}")
      exercises = Exercise.course_gdocs_sheet_exercises(course, sheetname)

      expect(exercises.size).to eq(2)
      expect(exercises).to include(ex1)
      expect(exercises).to include(ex2)
      expect(exercises).not_to include(ex3)
    end
  end

  describe 'associated submissions' do
    before :each do
      @exercise = FactoryGirl.create(:exercise, course: course, name: 'MyExercise')
      @submission_attrs = {
        course: course,
        exercise_name: 'MyExercise',
        user: user
      }
      Submission.create!(@submission_attrs)
      Submission.create!(@submission_attrs)
      @submissions = Submission.all
    end

    it 'should be associated by exercise name' do
      expect(@exercise.submissions.size).to eq(2)
      expect(@submissions[0].exercise).to eq(@exercise)
      @submissions[0].exercise_name = 'AnotherExercise'
      @submissions[0].save!
      expect(@exercise.submissions.size).to eq(1)
    end
  end

  it 'knows which exercise groups it belongs to' do
    ex = FactoryGirl.create(:exercise, course: course, name: 'foo-bar-baz')

    expect(ex.exercise_group_name).to eq('foo-bar')
    expect(ex.exercise_group.name).to eq('foo-bar')
    expect(ex.exercise_group.parent.name).to eq('foo')
    expect(ex.belongs_to_exercise_group?(ex.exercise_group)).to eq(true)
    expect(ex.belongs_to_exercise_group?(ex.exercise_group.parent)).to eq(true)

    ex2 = FactoryGirl.create(:exercise, course: course, name: 'xoo-bar-baz')
    course.reload
    another_course = FactoryGirl.create(:course)
    ex3 = FactoryGirl.create(:exercise, course: another_course, name: 'foo-bar-baz')

    expect(ex.belongs_to_exercise_group?(ex2.exercise_group)).to eq(false)
    expect(ex.belongs_to_exercise_group?(ex3.exercise_group)).to eq(false)
  end

  it "can be hidden with a boolean 'hidden' option" do
    ex = FactoryGirl.create(:exercise, course: course)
    ex.options = { 'hidden' => true }
    expect(ex).to be_hidden
  end

  def set_deadline(ex, t)
    if t.is_a? Array
      ex.deadline_spec = t.to_json
    else
      ex.deadline_spec = [t.to_s].to_json
    end
  end

  it 'should treat date deadlines as being at 23:59:59 local time' do
    ex = FactoryGirl.create(:exercise, course: course)
    set_deadline(ex, Date.today)
    expect(ex.deadline_for(user)).to eq(Date.today.end_of_day)
  end

  it 'should accept deadlines in either SQLish or Finnish date format' do
    ex = FactoryGirl.create(:exercise, course: course)

    set_deadline(ex, '2011-04-19 13:55')
    dl = ex.deadline_for(user)
    expect(dl.year).to eq(2011)
    expect(dl.month).to eq(04)
    expect(dl.day).to eq(19)
    expect(dl.hour).to eq(13)
    expect(dl.min).to eq(55)

    set_deadline(ex, '25.05.2012 14:56')
    dl = ex.deadline_for(user)
    expect(dl.day).to eq(25)
    expect(dl.month).to eq(5)
    expect(dl.year).to eq(2012)
    expect(dl.hour).to eq(14)
    expect(dl.min).to eq(56)
  end

  it 'should accept a blank deadline' do
    ex = FactoryGirl.create(:exercise, course: course)
    set_deadline(ex, nil)
    expect(ex.deadline_for(user)).to be_nil
    set_deadline(ex, '')
    expect(ex.deadline_for(user)).to be_nil
  end

  it 'should not accept certain hardcoded values for gdocs_sheet' do
    ex = FactoryGirl.create(:exercise, course: course)
    expect(ex.valid?).to be_truthy
    ex.gdocs_sheet = 'MASTER'
    expect(ex.valid?).to be_falsey
    ex.gdocs_sheet = 'PUBLIC'
    expect(ex.valid?).to be_falsey
    ex.gdocs_sheet = 'nonPUBLIC'
    expect(ex.valid?).to be_truthy
    ex.gdocs_sheet = 'nonMASTER'
    expect(ex.valid?).to be_truthy
  end

  it 'should raise an exception if trying to set a deadline in invalid format' do
    ex = FactoryGirl.create(:exercise)
    expect { set_deadline(ex, 'xooxers') }.to raise_error
    expect { set_deadline(ex, '2011-07-13 12:34:56:78') }.to raise_error
  end

  it "should always be submittable by administrators as long as it's returnable" do
    admin = FactoryGirl.create(:admin)
    ex = FactoryGirl.create(:returnable_exercise, course: course)

    expect(ex.deadline_for(user)).to be_nil
    expect(ex).to be_submittable_by(admin)

    set_deadline(ex, Date.today - 1.day)
    expect(ex).to be_submittable_by(admin)

    ex.hidden = true
    expect(ex).to be_submittable_by(admin)

    ex.options = { 'returnable' => false }
    expect(ex).not_to be_submittable_by(admin)
  end

  it 'should be submittable by non-administrators only if the deadline has not passed and the exercise is not hidden and is published' do
    # TODO: publish_time too!
    user = FactoryGirl.create(:user)
    ex = FactoryGirl.create(:returnable_exercise, course: course)

    expect(ex.deadline_for(user)).to be_nil
    expect(ex.publish_time).to be_nil
    expect(ex).to be_submittable_by(user)

    ex.publish_time = Date.today + 1.day
    expect(ex).not_to be_submittable_by(user)

    ex.publish_time = Date.today - 1.day
    expect(ex).to be_submittable_by(user)

    set_deadline(ex, Date.today + 1.day)
    expect(ex).to be_submittable_by(user)

    set_deadline(ex, Date.today - 1.day)
    expect(ex).not_to be_submittable_by(user)

    set_deadline(ex, nil)
    ex.hidden = true
    expect(ex).not_to be_submittable_by(user)
  end

  it 'should never be submittable by guests' do
    ex = FactoryGirl.create(:returnable_exercise, course: course)

    expect(ex).not_to be_submittable_by(Guest.new)
  end

  it 'should be visible to regular users by default' do
    user = FactoryGirl.create(:user)
    ex = FactoryGirl.create(:exercise, course: course)

    expect(ex).to be_visible_to(user)
  end

  it 'should not be visible to regular users if explicitly hidden' do
    user = FactoryGirl.create(:user)
    ex = FactoryGirl.create(:exercise, course: course, hidden: true)

    expect(ex).not_to be_visible_to(user)
  end

  it 'should not be visible to regular users if the publish time has not passed' do
    user = FactoryGirl.create(:user)
    ex = FactoryGirl.create(:exercise, course: course, publish_time: Time.now + 10.hours)

    expect(ex).not_to be_visible_to(user)
  end

  it 'should be visible to administrators even if publish time is in the future' do
    admin = FactoryGirl.create(:admin)
    ex = FactoryGirl.create(:exercise, course: course, publish_time: Time.now + 10.hours, hidden: false)

    expect(ex).to be_visible_to(admin)
  end

  it 'should be visible to administrators even if hidden' do
    admin = FactoryGirl.create(:admin)
    ex = FactoryGirl.create(:exercise, course: course, publish_time: Time.now - 10.hours, hidden: true)

    expect(ex).to be_visible_to(admin)
  end

  it 'can tell whether a user has ever attempted an exercise' do
    exercise = FactoryGirl.create(:exercise, course: course)
    expect(exercise).not_to be_attempted_by(user)

    Submission.create!(user: user, course: course, exercise_name: exercise.name, processed: false)
    expect(exercise).not_to be_attempted_by(user)

    Submission.create!(user: user, course: course, exercise_name: exercise.name, processed: true)
    exercise.reload
    expect(exercise).to be_attempted_by(user)
  end

  it 'can tell whether a user has completed an exercise' do
    exercise = FactoryGirl.create(:exercise, course: course)
    expect(exercise).not_to be_completed_by(user)

    other_user = FactoryGirl.create(:user)
    other_user_sub = Submission.create!(user: other_user, course: course, exercise_name: exercise.name, all_tests_passed: true)
    expect(exercise).not_to be_completed_by(user)

    Submission.create!(user: user, course: course, exercise_name: exercise.name, pretest_error: 'oops', all_tests_passed: true) # in reality all_tests_passed should always be false if pretest_error is not null
    expect(exercise).not_to be_completed_by(user)

    sub = Submission.create!(user: user, course: course, exercise_name: exercise.name, all_tests_passed: false)
    expect(exercise).not_to be_completed_by(user)
  end

  it 'can tell its available review points' do
    exercise = FactoryGirl.create(:exercise, course: course)
    pt1 = FactoryGirl.create(:available_point, exercise: exercise, requires_review: false)
    pt2 = FactoryGirl.create(:available_point, exercise: exercise, requires_review: true)
    pt3 = FactoryGirl.create(:available_point, exercise: exercise, requires_review: true)

    expect(exercise.available_review_points.sort).to eq([pt2, pt3].map(&:name).sort)
  end

  it "can tell if it's been reviewed for a user" do
    exercise = FactoryGirl.create(:exercise, course: course)

    expect(exercise).not_to be_reviewed_for(user)
    submission = FactoryGirl.create(:submission, exercise: exercise, course: course, user: user, reviewed: true)
    FactoryGirl.create(:review, submission: submission)
    exercise.reload
    expect(exercise).to be_reviewed_for(user)
  end

  it 'can tell if all review points have been given to a user' do
    exercise = FactoryGirl.create(:exercise, course: course)
    pt1 = FactoryGirl.create(:available_point, exercise: exercise, requires_review: false)
    pt2 = FactoryGirl.create(:available_point, exercise: exercise, requires_review: true)
    pt3 = FactoryGirl.create(:available_point, exercise: exercise, requires_review: true)

    FactoryGirl.create(:awarded_point, course: course, user: user, name: pt2.name)
    expect(exercise).not_to be_all_review_points_given_for(user)
    FactoryGirl.create(:awarded_point, course: course, user: user, name: pt3.name)
    expect(exercise).to be_all_review_points_given_for(user)
  end

  it 'can tell which review point are missing for a user' do
    exercise = FactoryGirl.create(:exercise, course: course)
    pt1 = FactoryGirl.create(:available_point, exercise: exercise, requires_review: false)
    pt2 = FactoryGirl.create(:available_point, exercise: exercise, requires_review: true)
    pt3 = FactoryGirl.create(:available_point, exercise: exercise, requires_review: true)

    FactoryGirl.create(:awarded_point, course: course, user: user, name: pt2.name)
    expect(exercise.missing_review_points_for(user)).to eq([pt3.name])
  end
end
