# frozen_string_literal: true

class SettingsController < ApplicationController
  skip_authorization_check

  before_action :set_user

  def show
    authorize! :read, @user
  end

  def update
    authorize! :update, @user
    set_email
    password_changed = maybe_update_password(@user, params[:user])
    user_field_changes = set_user_fields

    begin
      log_user_field_changes(user_field_changes)
    rescue StandardError
    end

    if @user.errors.empty? && @user.save
      flash[:notice] = if password_changed
        'Changes saved and password changed'
      else
        'Changes saved'
      end
      redirect_to participant_settings_path(@user)
    else
      flash.now[:error] = 'Failed to save profile'
      render action: :show, status: :forbidden
    end
  end

  def dangerously_destroy_user
    @user = authenticate_current_user_destroy
    if @user.submissions.length != 0
      redirect_to user_has_submissions_participant_settings_url
      return
    end
    im_sure = params[:im_sure]
    if im_sure != '1'
      redirect_to verify_dangerously_destroying_user_participant_settings_url, notice: 'Please check the checkbox after you have read the instructions.'
      return
    end
    username = @user.login
    sign_out if current_user == @user
    email = @user.email
    username = @user.login
    @user.destroy
    RecentlyChangedUserDetail.deleted.create!(old_value: false, new_value: true, email: email, username: username)
    redirect_to root_url, notice: "The account #{username} (#{email}) has been permanently destroyed."
  end

  def verify_dangerously_destroying_user
    @user = authenticate_current_user_destroy
  end

  def user_has_submissions
    @user = authenticate_current_user_destroy
  end

  private

    def authenticate_current_user_destroy
      user = User.find(params[:participant_id])
      authorize! :destroy, user
      user
    end

    def set_user
      @user = User.find(params[:participant_id])
    end

    def set_email
      user_params = params[:user]

      return if !@user.new_record? && user_params[:email_repeat].blank?

      if user_params[:email].blank?
        @user.errors.add(:email, 'needed')
      elsif user_params[:email] != user_params[:email_repeat]
        @user.errors.add(:email_repeat, 'did not match')
      else
        @user.email = user_params[:email].strip
      end
    end

    def maybe_update_password(user, user_params)
      if user_params[:old_password].present? || user_params[:password].present?
        if !user.has_password?(user_params[:old_password])
          user.errors.add(:old_password, 'incorrect')
        elsif user_params[:password] != user_params[:password_repeat]
          user.errors.add(:password_repeat, 'did not match')
        elsif user_params[:password].blank?
          user.errors.add(:password, 'cannot be empty')
        elsif user_params[:password].length > 1000
          user.errors.add(:password, 'cannot be over 1000 characters')
        else
          user.password = user_params[:password]
        end
        true
      else
        false
      end
    end

    def set_user_fields
      return if params[:user_field].nil?
      changes = {}
      UserField.all.select { |f| f.visible_to?(current_user) }.each do |field|
        value_record = @user.field_value_record(field)
        old_value = value_record.ruby_value
        value_record.set_from_form(params[:user_field][field.name])
        new_value = value_record.ruby_value
        changes[field.name] = { from: old_value, to: new_value } unless new_value == old_value
      end
      changes
    end
end
