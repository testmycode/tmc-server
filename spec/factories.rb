FactoryGirl.define do
  factory :user do
    sequence(:login) {|n| "user#{n}" }
    sequence(:password) {|n| "userpass#{n}" }
    sequence(:email) {|n| "user#{n}@example.com" }
    administrator false
  end

  factory :admin, :class => User do
    sequence(:login) {|n| 'admin#{n}' }
    sequence(:password) {|n| "adminpass#{n}" }
    sequence(:email) {|n| "admin#{n}@example.com" }
    administrator true
  end

  factory :course, :class => Course do
    sequence(:name) {|n| "course#{n}" }
    source_url 'git@example.com'
  end

  factory :exercise do
    course
    sequence(:name) {|n| "exercise#{n}" }
    sequence(:gdocs_sheet) {|n| "exercise#{n}" }
  end
  
  factory :returnable_exercise, :parent => :exercise do
    returnable_forced true
  end

  factory :submission do
    course
    user
    exercise
    processed true
    after_build { |sub| sub.exercise.course = sub.course }
  end

  factory :awarded_point do
    course
    sequence(:name) {|n| "point#{n}" }
    submission
    user
    after_build { |pt| pt.submission.course = pt.course }
  end

  factory :available_point do
    sequence(:name) {|n| "point#{n}" }
    exercise
  end

  factory :test_case_run do
    sequence(:test_case_name) {|n| "test case #{n}" }
    submission
    successful false
  end
  
  factory :feedback_question do
    course
    sequence(:question) {|n| "feedback question #{n}" }
    kind 'text'
  end
  
  factory :feedback_answer do
    feedback_question
    course
    exercise
    submission
    sequence(:answer) {|n| "feedback answer #{n}" }
  end
end
