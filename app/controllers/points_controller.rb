class PointsController < ApplicationController
  def index
  
    @points_status = Point.order("(created_at)DESC LIMIT 50")
    @points_in_queue = PointsUploadQueue.all
   

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @points_status }
    end
  end

  def upload_to_gdocs
    errors = PointsUploadQueue.upload_to_gdocs
    redirect_to courses_path, :alert => errors[:error]
  end

end
