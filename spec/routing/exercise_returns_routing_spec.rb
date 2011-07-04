require "spec_helper"
=begin
describe ExerciseReturnsController do
  describe "routing" do

    it "routes to #index" do
      get("/exercise_returns").should route_to("exercise_returns#index")
    end

    it "routes to #new" do
      get("/exercise_returns/new").should route_to("exercise_returns#new")
    end

    it "routes to #show" do
      get("/exercise_returns/1").should route_to("exercise_returns#show", :id => "1")
    end

    it "routes to #edit" do
      get("/exercise_returns/1/edit").should route_to("exercise_returns#edit", :id => "1")
    end

    it "routes to #create" do
      post("/exercise_returns").should route_to("exercise_returns#create")
    end

    it "routes to #update" do
      put("/exercise_returns/1").should route_to("exercise_returns#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/exercise_returns/1").should route_to("exercise_returns#destroy", :id => "1")
    end

  end
end
=end
