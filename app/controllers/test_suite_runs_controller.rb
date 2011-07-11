class TestSuiteRunsController < ApplicationController
  def index
    @test_suite_runs = TestSuiteRun.all

    respond_to do |format|
      format.html
      format.xml  { render :xml => @test_suite_runs }
    end
  end

  def show
    @test_suite_run = TestSuiteRun.find(params[:id])
    @test_case_runs = @test_suite_run.test_case_runs.order("exercise, class_name, method_name")

    respond_to do |format|
      format.html
      format.json { render :json => @test_case_runs }
    end
  end
end
