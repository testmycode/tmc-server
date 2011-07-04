class UsersController < ApplicationController

  def show
    #@user = User.find(params[:id])
    #@title = @user.name
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      sign_in @user
      redirect_to @user
    else
      #@title = "Sign up"
      render 'new'
    end
  end


end
