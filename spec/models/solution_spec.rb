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
    SiteSetting.all_settings['show_model_solutions_when_exercise_completed'] = true
    SiteSetting.all_settings['show_model_solutions_when_exercise_expired'] = true
  
    user = Factory.create(:user)
    ex = Factory.create(:exercise)
    sol = ex.solution
    
    ex.stub(:submittable_by?).and_return(true)
    sol.should_not be_visible_to(user)
  end
end
