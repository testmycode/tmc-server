FactoryGirl.define do
  factory :user do
    sequence(:login) {|n| "user#{n}" }
    administrator false
  end

  factory :admin, :class => User do
    sequence(:login) {|n| 'admin#{n}' }
    password 'adminpass'
    administrator true
  end

  factory :course, :class => Course do
    sequence(:name) {|n| "course#{n}" }
    remote_repo_url 'git@example.com'
  end

  factory :exercise do
    course
    sequence(:name) {|n| "exercise#{n}" }
    sequence(:gdocs_sheet) {|n| "exercise#{n}" }
  end

  factory :submission do
    course
    user
    exercise
  end

  factory :awarded_point do
    course
    sequence(:name) {|n| "point#{n}" }
    submission
    user
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
end
