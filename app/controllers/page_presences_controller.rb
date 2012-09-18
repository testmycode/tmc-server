class PagePresencesController < ApplicationController
  def update
    authorize! :update, PagePresence
    path = params[:path]
    PagePresence.refresh(current_user, path)
    PagePresence.delete_older_than_timeout

    respond_to do |format|
      format.json do
        visitors = PagePresence.visitors_of(path).map(&:username) - [current_user.username]
        render :json => visitors
      end
    end
  end
end