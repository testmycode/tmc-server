require 'spec_helper'

describe "/api/beta/participant_controller", type: :request, integration: true  do

  before :each do
    @course = FactoryGirl.create(:course)

    @user = FactoryGirl.create(:user)
    @token = Doorkeeper::AccessToken.create!(:application_id => 1212313, :resource_owner_id => @user.id, scopes: "public").token

    @sheet1 = 'sheet1'
    @sheet2 = 'sheet2'

    @ex1 = FactoryGirl.create(:exercise, course: @course,
                              gdocs_sheet: @sheet1)
    @ex2 = FactoryGirl.create(:exercise, course: @course,
                              gdocs_sheet: @sheet2)
    @ex3 = FactoryGirl.create(:exercise, course: @course,
                              gdocs_sheet: @sheet2)


    @sub1 = FactoryGirl.create(:submission, course: @course,
                               user: @user,
                               exercise: @ex1)
    @sub2 = FactoryGirl.create(:submission, course: @course,
                               user: @user,
                               exercise: @ex2)

    @sub1.submission_data = FactoryGirl.create(:submission_data, submission: @sub1)
    @sub2.submission_data = FactoryGirl.create(:submission_data, submission: @sub2)

    FactoryGirl.create(:available_point, exercise: @ex1, name: 'ap')
    FactoryGirl.create(:available_point, exercise: @ex2, name: 'ap2')

    @ap = FactoryGirl.create(:awarded_point, course: @course,
                             user: @user, name: 'ap',
                             submission: @sub1)
    @ap2 = FactoryGirl.create(:awarded_point, course: @course,
                              user: @user, name: 'ap2',
                              submission: @sub2)
  end

  it "Returns collection of requesters course record" do
    get("/api/beta/participant/courses?access_token=#{@token}")
    data = JSON.parse(response.body.gsub(/\d+/, "0"))
    expect(data).to eq(
      [
        {
          "id"=>0,
          "name"=>"course0",
          "title"=>"Course 0",
          "details_url"=>"http://www.example.com/org/organization0/courses/0.json",
          "unlock_url"=>"http://www.example.com/org/organization0/courses/0/unlock.json",
          "reviews_url"=>"http://www.example.com/org/organization0/courses/0/reviews.json",
          "comet_url"=>"http://localhost:0/comet",
          "spyware_urls"=>["http://localhost:0/"],
          "exercises"=>[
            {
              "exercise_name"=>"exercise0",
              "exercise_id"=>0,
              "submissions_count"=>0,
              "all_tests_passed"=>false,
              "got_all_points"=>true,
              "available_points"=>["ap"],
              "awarded_points"=>["ap"]
            },
            {
              "exercise_name"=>"exercise0",
              "exercise_id"=>0,
              "submissions_count"=>0,
              "all_tests_passed"=>false,
              "got_all_points"=>true,
              "available_points"=>["ap0"],
              "awarded_points"=>["ap0"]
            },
            {"exercise_name"=>"exercise0",
             "exercise_id"=>0,
             "submissions_count"=>0,
             "all_tests_passed"=>false,
             "got_all_points"=>true,
             "available_points"=>nil,
             "awarded_points"=>nil
            }
          ]
        }
      ]
    )
  end
end
