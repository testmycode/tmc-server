require 'spec_helper'

describe Assistantship, type: :model do
  it 'creates assistantship between course and user' do
    user1 = FactoryGirl.create :user
    user2 = FactoryGirl.create :user
    course1 = FactoryGirl.create :course
    course2 = FactoryGirl.create :course
    Assistantship.create! user: user1, course: course1
    expect(user1.assisted_courses).to eq([course1])
    expect(user2.assisted_courses).to eq([])
    expect(course1.assistants).to eq([user1])
    expect(course2.assistants).to eq([])
  end

  it 'can\'t create assistantship if course is non-existant' do
    user = FactoryGirl.create :user
    course = FactoryGirl.create :course
    expect {Assistantship.create! user_id: user.id, course_id: course.id + 1}.to raise_error("Validation failed: Course can't be blank")
  end

  it 'can\'t create assistantship if user is non-existant' do
    user = FactoryGirl.create :user
    course = FactoryGirl.create :course
    expect {Assistantship.create! user_id: user.id + 1, course_id: course.id}.to raise_error("Validation failed: User does not exist")
  end

  it 'can\'t create assistantship if user already assistant' do
    user = FactoryGirl.create :user
    course = FactoryGirl.create :course
    Assistantship.create! user: user, course: course
    expect {Assistantship.create! user: user, course: course}.to raise_error("Validation failed: User is already an assistant for this course")
  end

  it 'leaves courses intact when user is destroyed, but courses don\'t have ghost assistants' do
    user = FactoryGirl.create :user
    course1 = FactoryGirl.create :course
    course2 = FactoryGirl.create :course
    course3 = FactoryGirl.create :course
    Assistantship.create! user: user, course: course1
    Assistantship.create! user: user, course: course2
    Assistantship.create! user: user, course: course3
    user.destroy!
    expect(Course.all.count).to eq(3)
    expect(Assistantship.all.count).to eq(0)
    expect(course1.assistants).to eq([])
    expect(course2.assistants).to eq([])
    expect(course3.assistants).to eq([])
  end

  it 'leaves assistants intact when course is destroyed, but users don\'t assist ghost courses' do
    course = FactoryGirl.create :course
    user1 = FactoryGirl.create :user
    user2 = FactoryGirl.create :user
    user3 = FactoryGirl.create :user
    Assistantship.create! user: user1, course: course
    Assistantship.create! user: user2, course: course
    Assistantship.create! user: user3, course: course
    course.destroy!
    expect(User.all.count).to eq(3)
    expect(Assistantship.all.count).to eq(0)
    expect(user1.assisted_courses).to eq([])
    expect(user2.assisted_courses).to eq([])
    expect(user3.assisted_courses).to eq([])
  end

  it 'user\'s and course\'s assistant? method works' do
    user1 = FactoryGirl.create :user
    user2 = FactoryGirl.create :user
    course1 = FactoryGirl.create :course
    course2 = FactoryGirl.create :course
    Assistantship.create! user: user1, course: course1
    expect(user1.assistant? course1).to be true
    expect(user1.assistant? course2).to be false
    expect(course1.assistant? user1).to be true
    expect(course1.assistant? user2).to be false
  end
end
