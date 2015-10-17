require 'spyware_client'

# Presents the "register user" and "edit profile" views.
class UsersController < ApplicationController
  skip_authorization_check

  after_action :remove_x_frame_options_header_when_bare_layout, only: [:new, :create, :show]

  def new
    add_breadcrumb 'Sign up', new_user_path

    authorize! :create, User
    if signed_in?
      # Logged in from this page. No need to be here, so redirect away
      redirect_to root_path
    else
      @user = User.new
    end
  end

  def create
    authorize! :create, User

    @user = User.new

    @user.login = params[:user][:login].to_s.strip

    set_email
    set_password
    set_user_fields

    if @user.errors.empty? && @user.save
      send_email_confirmation_mail(@user)
      if @bare_layout
        render text: '<div class="success" style="font-size: 14pt; margin: 10pt;">User account created. Confirmation email has been sent to your email address.</div>', layout: true
      else
        flash[:notice] = 'User account created. Confirmation email has been sent to your email address.'
        redirect_to root_path
      end
    else
      flash.now[:error] = 'Failed'
      render action: :show, status: 403
    end
  end

  def show
    add_breadcrumb 'My account', user_path

    if current_user.guest?
      respond_access_denied
    else
      @user = current_user
    end
  end

  def update
    @user = current_user

    current_email = @user.email
    set_email
    password_changed = maybe_update_password(@user, params[:user])
    user_field_changes = set_user_fields

    begin
      log_user_field_changes(user_field_changes)
    rescue

    end

    if @user.errors.empty? && @user.save
      notice = 'Changes saved. '
      if current_email != @user.email
        send_email_confirmation_mail(@user)
        @user.update!(email_confirmed_at: nil)
        notice += 'Confirmation email has been sent to your new email address. '
      end
      notice += 'Password changed' if password_changed
      flash[:notice] = notice
      redirect_to user_path
    else
      flash.now[:error] = 'Failed to save profile'
      render action: :show, status: 403
    end
  end

  private

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

  def set_password
    user_params = params[:user]
    if user_params[:password].blank?
      @user.errors.add(:password, 'needed')
    elsif user_params[:password] != user_params[:password_repeat]
      @user.errors.add(:password_repeat, 'did not match')
    else
      @user.password = user_params[:password]
    end
  end

  def maybe_update_password(user, user_params)
    if !user_params[:old_password].blank? || !user_params[:password].blank?
      if !user.has_password?(user_params[:old_password])
        user.errors.add(:old_password, 'incorrect')
      elsif user_params[:password] != user_params[:password_repeat]
        user.errors.add(:password_repeat, 'did not match')
      elsif user_params[:password].blank?
        user.errors.add(:password, 'cannot be empty')
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

  def log_user_field_changes(changes)
    unless changes.empty?
      data = {
        eventType: 'user_fields_changed',
        changes: changes.clone,
        happenedAt: (Time.now.to_f * 1000).to_i
      }
      Thread.new do
        begin
          SpywareClient.send_data_to_any(data.to_json, current_user.username, request.session_options[:id])
        rescue
          logger.warn('Failed to send user field changes to spyware: ' + $!.message + "\n " + $!.backtrace.join("\n "))
        end
      end
    end
  end

  def send_email_confirmation_mail(user)
    token = ActionToken.generate_email_confirmation_token(user)
    EmailConfirmationMailer.confirmation_link_email(user, token).deliver
  end
end
