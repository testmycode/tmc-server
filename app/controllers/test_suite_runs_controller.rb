class TestSuiteRunsController < ApplicationController
  # GET /test_suite_runs
  # GET /test_suite_runs.xml
  def index
    @test_suite_runs = TestSuiteRun.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @test_suite_runs }
    end
  end

  # GET /test_suite_runs/1
  # GET /test_suite_runs/1.xml
  def show
    @test_suite_run = TestSuiteRun.find(params[:id])
    @test_case_runs =
      TestCaseRun.where(:test_suite_run_id => @test_suite_run.id) 

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @test_suite_run }
      format.json { render :json => @test_case_runs }
    end
  end

  # GET /test_suite_runs/new
  # GET /test_suite_runs/new.xml
  def new
    @test_suite_run = TestSuiteRun.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @test_suite_run }
    end
  end

  # GET /test_suite_runs/1/edit
  def edit
    @test_suite_run = TestSuiteRun.find(params[:id])
  end

  # POST /test_suite_runs
  # POST /test_suite_runs.xml
  def create
    @test_suite_run = TestSuiteRun.new(params[:test_suite_run])

    respond_to do |format|
      if @test_suite_run.save
        format.html { redirect_to(@test_suite_run, :notice => 'Test suite run was successfully created.') }
        format.xml  { render :xml => @test_suite_run, :status => :created, :location => @test_suite_run }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @test_suite_run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /test_suite_runs/1
  # PUT /test_suite_runs/1.xml
  def update
    @test_suite_run = TestSuiteRun.find(params[:id])

    respond_to do |format|
      if @test_suite_run.update_attributes(params[:test_suite_run])
        format.html { redirect_to(@test_suite_run, :notice => 'Test suite run was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @test_suite_run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /test_suite_runs/1
  # DELETE /test_suite_runs/1.xml
  def destroy
    @test_suite_run = TestSuiteRun.find(params[:id])
    @test_suite_run.destroy

    respond_to do |format|
      format.html { redirect_to(test_suite_runs_url) }
      format.xml  { head :ok }
    end
  end
end
