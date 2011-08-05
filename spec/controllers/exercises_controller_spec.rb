require 'spec_helper'

describe ExercisesController do
  describe "GET show" do
  
    let!(:course) { Factory.create(:course) }
    let!(:exercise) { Factory.create(:exercise, :course => course) }
  
    def get_show
      get :show, :course_id => course.id, :id => exercise.id
    end
  
    describe "for guests" do
      it "should not show submissions" do
        get_show
        assigns[:submissions].should be_nil
      end
    end
    
    describe "for users" do
      let!(:user) { Factory.create(:user) }
      before :each do
        controller.current_user = user
      end
      it "should not show the user's submissions" do
        s1 = Factory.create(:submission, :course => course, :exercise => exercise, :user => user)
        s2 = Factory.create(:submission, :course => course, :exercise => exercise)
        
        get_show
        
        assigns[:submissions].should include(s1)
        assigns[:submissions].should_not include(s2)
      end
    end
    
    describe "for administrators" do
      before :each do
        controller.current_user = Factory.create(:admin)
      end
      it "should show all submissions" do
        s1 = Factory.create(:submission, :course => course, :exercise => exercise)
        s2 = Factory.create(:submission, :course => course, :exercise => exercise)
        irrelevant = Factory.create(:submission)
        
        get_show
        
        assigns[:submissions].should include(s1)
        assigns[:submissions].should include(s2)
        assigns[:submissions].should_not include(irrelevant)
      end
    end
  end
end
