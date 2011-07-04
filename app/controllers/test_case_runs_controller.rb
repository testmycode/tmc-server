class TestCaseRunsController < ApplicationController
  # GET /test_case_runs
  # GET /test_case_runs.xml
  def index
    @test_case_runs = TestCaseRun.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @test_case_runs }
    end
  end

  # GET /test_case_runs/1
  # GET /test_case_runs/1.xml
  def show
    @test_case_run = TestCaseRun.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @test_case_run }
    end
  end

  # GET /test_case_runs/new
  # GET /test_case_runs/new.xml
  def new
    @test_case_run = TestCaseRun.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @test_case_run }
    end
  end

  # GET /test_case_runs/1/edit
  def edit
    @test_case_run = TestCaseRun.find(params[:id])
  end

  # POST /test_case_runs
  # POST /test_case_runs.xml
  def create
    @test_case_run = TestCaseRun.new(params[:test_case_run])

    respond_to do |format|
      if @test_case_run.save
        format.html { redirect_to(@test_case_run, :notice => 'Test case run was successfully created.') }
        format.xml  { render :xml => @test_case_run, :status => :created, :location => @test_case_run }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @test_case_run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /test_case_runs/1
  # PUT /test_case_runs/1.xml
  def update
    @test_case_run = TestCaseRun.find(params[:id])

    respond_to do |format|
      if @test_case_run.update_attributes(params[:test_case_run])
        format.html { redirect_to(@test_case_run, :notice => 'Test case run was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @test_case_run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /test_case_runs/1
  # DELETE /test_case_runs/1.xml
  def destroy
    @test_case_run = TestCaseRun.find(params[:id])
    @test_case_run.destroy

    respond_to do |format|
      format.html { redirect_to(test_case_runs_url) }
      format.xml  { head :ok }
    end
  end
end
