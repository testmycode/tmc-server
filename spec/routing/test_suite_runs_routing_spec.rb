require "spec_helper"

describe TestSuiteRunsController do
  describe "routing" do

    it "routes to #index" do
      get("/test_suite_runs").should route_to("test_suite_runs#index")
    end

    it "routes to #new" do
      get("/test_suite_runs/new").should route_to("test_suite_runs#new")
    end

    it "routes to #show" do
      get("/test_suite_runs/1").should route_to("test_suite_runs#show", :id => "1")
    end

    it "routes to #edit" do
      get("/test_suite_runs/1/edit").should route_to("test_suite_runs#edit", :id => "1")
    end

    it "routes to #create" do
      post("/test_suite_runs").should route_to("test_suite_runs#create")
    end

    it "routes to #update" do
      put("/test_suite_runs/1").should route_to("test_suite_runs#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/test_suite_runs/1").should route_to("test_suite_runs#destroy", :id => "1")
    end

  end
end
