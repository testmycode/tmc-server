require 'spec_helper'

describe ExercisesController, :type => :controller do
  describe "GET show" do

    let!(:course) { FactoryGirl.create(:course) }
    let!(:exercise) { FactoryGirl.create(:exercise, :course => course) }

    def get_show
      get :show, :id => exercise.id
    end

    describe "for guests" do
      it "should not show submissions" do
        get_show
        expect(assigns[:submissions]).to be_nil
      end
    end

    describe "for users" do
      let!(:user) { FactoryGirl.create(:user) }
      before :each do
        controller.current_user = user
      end
      it "should not show the user's submissions" do
        s1 = FactoryGirl.create(:submission, :course => course, :exercise => exercise, :user => user)
        s2 = FactoryGirl.create(:submission, :course => course, :exercise => exercise)

        get_show

        expect(assigns[:submissions]).not_to be_nil
        expect(assigns[:submissions]).to include(s1)
        expect(assigns[:submissions]).not_to include(s2)
      end
    end

    describe "for administrators" do
      before :each do
        controller.current_user = FactoryGirl.create(:admin)
      end
      it "should show all submissions" do
        s1 = FactoryGirl.create(:submission, :course => course, :exercise => exercise)
        s2 = FactoryGirl.create(:submission, :course => course, :exercise => exercise)
        irrelevant = FactoryGirl.create(:submission)

        get_show

        expect(assigns[:submissions]).not_to be_nil
        expect(assigns[:submissions]).to include(s1)
        expect(assigns[:submissions]).to include(s2)
        expect(assigns[:submissions]).not_to include(irrelevant)
      end
    end
  end
end
