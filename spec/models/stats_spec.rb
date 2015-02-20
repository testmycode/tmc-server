require 'spec_helper'

describe Stats, type: :model do
  it 'should give interesting statistics about the system' do
    course1 = FactoryGirl.create(:course, name: 'course1')
    course2 = FactoryGirl.create(:course, name: 'course2')
    cat1ex1 = FactoryGirl.create(:exercise, course: course1, name: 'cat1-ex1')
    cat1ex2 = FactoryGirl.create(:exercise, course: course1, name: 'cat1-ex2')
    cat2ex1 = FactoryGirl.create(:exercise, course: course1, name: 'cat2-ex1')
    cat3ex1 = FactoryGirl.create(:exercise, course: course2, name: 'cat3-ex1')
    hiddenex = FactoryGirl.create(:exercise, course: course1, name: 'cat1-hiddenex', hidden: true)

    user1 = FactoryGirl.create(:user)
    user2 = FactoryGirl.create(:user)
    user3 = FactoryGirl.create(:user)
    create_successful_submission(course: course1, exercise: cat1ex1, user: user1)
    create_successful_submission(course: course1, exercise: cat1ex1, user: user2)
    create_successful_submission(course: course1, exercise: cat1ex2, user: user1)
    create_successful_submission(course: course1, exercise: cat2ex1, user: user1)
    create_successful_submission(course: course2, exercise: cat3ex1, user: user1)

    stats = Stats.all

    expect(stats[:registered_users]).to eq(3)

    cs = stats[:course_stats]
    expect(cs['course1'][:participants_with_submissions_count]).to eq(2)
    expect(cs['course1'][:completed_exercise_count]).to eq(4)
    expect(cs['course1'][:possible_completed_exercise_count]).to eq(6) # 2 users with subs and 3 exercises
    expect(cs['course2'][:participants_with_submissions_count]).to eq(1)
    expect(cs['course2'][:completed_exercise_count]).to eq(1)
    expect(cs['course2'][:possible_completed_exercise_count]).to eq(1) # 1 user with subs and 1 exercise

    egs = cs['course1'][:exercise_group_stats]
    expect(egs['cat1'][:participants_with_submissions_count]).to eq(2)
    expect(egs['cat1'][:completed_exercise_count]).to eq(3)
    expect(egs['cat1'][:possible_completed_exercise_count]).to eq(4)
    expect(egs['cat2'][:participants_with_submissions_count]).to eq(1)
    expect(egs['cat2'][:completed_exercise_count]).to eq(1)
    expect(egs['cat2'][:possible_completed_exercise_count]).to eq(1)
  end

  def create_successful_submission(opts)
    sub = FactoryGirl.create(:submission, opts.merge(all_tests_passed: true))
    FactoryGirl.create(:test_case_run, submission: sub, successful: true)
    expect(sub.status).to eq(:ok)
    sub
  end
end
