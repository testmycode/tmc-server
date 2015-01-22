require 'spec_helper'

describe Solution, type: :model do
  it "should be visible if solution_visible_after has passed" do
    user = FactoryGirl.create(:user)
    ex = FactoryGirl.create(:exercise)
    sol = ex.solution

    ex.solution_visible_after = Time.now - 5.days
    expect(sol).to be_visible_to(user)
  end

  it "should never be visible if exercise is still submittable and uncompleted by a non-admin user" do
    show_when_completed(true)
    show_when_expired(true)

    user = FactoryGirl.create(:user)
    ex = FactoryGirl.create(:exercise)
    sol = ex.solution

    allow(ex).to receive(:submittable_by?).and_return(true)
    expect(sol).not_to be_visible_to(user)
  end

  it "should not be visible if the exercise is not visible to the user" do
    show_when_completed(true)
    show_when_expired(true)

    user = FactoryGirl.create(:user)
    ex = FactoryGirl.create(:exercise)
    sol = ex.solution

    ex.solution_visible_after = Time.now - 5.days
    expect(sol).to be_visible_to(user)

    allow(ex).to receive("visible_to?").and_return(false)
    expect(sol).not_to be_visible_to(user)
  end

  def show_when_completed(setting)
    SiteSetting.all_settings['show_model_solutions_when_exercise_completed'] = setting
  end

  def show_when_expired(setting)
    SiteSetting.all_settings['show_model_solutions_when_exercise_expired'] = setting
  end
end
