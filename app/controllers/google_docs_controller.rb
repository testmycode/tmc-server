class GoogleDocsController < ApplicationController
  before_filter :google_setup

  def index
    if not params[:folder_id]
      #Display all files and root folders
      @documents = @account.files
      @folders = @account.folders.select{|f| !f.parent }
      #display only root folders
    else
      #Display only files and folders contained by folder_id
      @folder = Folder.find(@account, {:id => params[:folder_id]})
      @documents = @folder.files
      @folders = @folder.folders
    end
  end
end

