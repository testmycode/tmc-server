class StatsController < ApplicationController
  skip_authorization_check
  
  def index
    @stats = Stats.all
    respond_to do |format|
      format.html { render }
      format.json { render :json => @stats }
    end
  end
end
