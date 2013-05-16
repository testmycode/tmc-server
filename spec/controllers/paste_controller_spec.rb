require 'spec_helper'

describe PasteController do


  describe "for an admin user " do
    it "shows submission as paste anyway if user ia admin" do
      @admin = Factory.create(:admin, :email => "admin@mydomain.com")
      @user = Factory.create(:user)
      @course = Factory.create(:course, :name => 'Course1')
      @exercise = Factory.create(:returnable_exercise, :name => 'Exercise1', :course => @course)
      @course.exercises << @exercise
      @submission = Factory.create(:submission,
                                   :course => @course,
                                   :user => @user,
                                   :exercise => @exercise,
                                   :paste_available => true,
                                   :created_at => 3.days.ago)
      controller.current_user = @admin
      #TODO how to test it just works...
    end
  end

  describe "for normal user" do
    it "it doesn't show paste if its not available" do
      @admin = Factory.create(:admin, :email => "admin@mydomain.com")
      @user = Factory.create(:user)
      @course = Factory.create(:course, :name => 'Course1')
      @exercise = Factory.create(:returnable_exercise, :name => 'Exercise1', :course => @course)
      @course.exercises << @exercise
      @submission = Factory.create(:submission,
                                   :course => @course,
                                   :user => @user,
                                   :exercise => @exercise,
                                   :paste_available => false,
                                   :created_at => 1.days.ago)
      controller.current_user = @user
      #TODO how to test it just works...
    end

    it "it doesn't show paste if its available but expired" do
      @admin = Factory.create(:admin, :email => "admin@mydomain.com")
      @user = Factory.create(:user)
      @course = Factory.create(:course, :name => 'Course1')
      @exercise = Factory.create(:returnable_exercise, :name => 'Exercise1', :course => @course)
      @course.exercises << @exercise
      @submission = Factory.create(:submission,
                                   :course => @course,
                                   :user => @user,
                                   :exercise => @exercise,
                                   :paste_available => true,
                                   :created_at => 10.days.ago)
      controller.current_user = @user
      #TODO how to test it just works...
    end

  end
end