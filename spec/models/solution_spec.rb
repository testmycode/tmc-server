require 'spec_helper'

describe Solution do
  it "should be visible if solution_visible_after has passed" do
    user = Factory.create(:user)
    ex = Factory.create(:exercise)
    sol = ex.solution
    
    ex.solution_visible_after = Time.now - 5.days
    sol.should be_visible_to(user)
  end

  it "should never be visible if exercise is still submittable and uncompleted by a non-admin user" do
    show_when_completed(true)
    show_when_expired(true)
  
    user = Factory.create(:user)
    ex = Factory.create(:exercise)
    sol = ex.solution
    
    ex.stub(:submittable_by?).and_return(true)
    sol.should_not be_visible_to(user)
  end

  it "should not be visible if the exercise is not visible to the user" do
    show_when_completed(true)
    show_when_expired(true)

    user = Factory.create(:user)
    ex = Factory.create(:exercise)
    sol = ex.solution

    ex.solution_visible_after = Time.now - 5.days
    sol.should be_visible_to(user)

    ex.stub("visible_to?").and_return(false)
    sol.should_not be_visible_to(user)
  end

  def show_when_completed(setting)
    SiteSetting.all_settings['show_model_solutions_when_exercise_completed'] = setting
  end

  def show_when_expired(setting)
    SiteSetting.all_settings['show_model_solutions_when_exercise_expired'] = setting
  end
end
