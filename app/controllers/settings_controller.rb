# typed: strict
# frozen_string_literal: true

class SettingsController < ApplicationController
  extend T::Sig
  include AccountCredentialsForm
  skip_authorization_check

  before_action :set_user

  sig { void }
  def show
    authorize! :read, @user
  end

  sig { void }
  def update
    authorize! :update, @user
    user = T.must(@user)

    User.transaction do
      email_before = user.email
      @email_before = T.let(email_before, T.nilable(String))
      password_changed = apply_credentials(user, params.fetch(:user, {}))
      set_user_fields

      if user.errors.empty? && user.save
        # Password changed locally: migrate the user to courses.mooc.fi
        user.post_new_user_to_courses_mooc_fi(params[:user][:password]) if password_changed
        RecentlyChangedUserDetail.email_changed.create!(old_value: email_before, new_value: user.email, username: user.login, user_id: user.id) unless T.must(email_before.casecmp(user.email)).zero?
        flash[:notice] = if password_changed
          'Changes saved and password changed'
        else
          'Changes saved'
        end
        redirect_to participant_settings_path(user)
      else
        flash.now[:error] = 'Failed to save profile'
        render action: :show, status: :forbidden
      end
    end
  end

  sig { void }
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
    sign_out if current_user == @user
    email = @user.email
    username = @user.login
    @user.destroy
    RecentlyChangedUserDetail.deleted.create!(old_value: false, new_value: true, email: email, username: username)
    redirect_to root_url, notice: "The account #{username} (#{email}) has been permanently destroyed."
  end

  sig { void }
  def verify_dangerously_destroying_user
    @user = authenticate_current_user_destroy
  end

  sig { void }
  def user_has_submissions
    @user = authenticate_current_user_destroy
  end

  private
    sig { returns(User) }
    def authenticate_current_user_destroy
      user = User.find(params[:participant_id])
      authorize! :destroy, user
      user
    end

    sig { void }
    def set_user
      @user = T.let(User.find(params[:participant_id]), T.nilable(User))
    end

    sig { returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
    def set_user_fields
      return if params[:user_field].nil?
      changes = {}
      UserField.all.select { |f| f.visible_to?(current_user) }.each do |field|
        value_record = T.must(@user).field_value_record(field)
        old_value = value_record.ruby_value
        value_record.set_from_form(params[:user_field][field.name])
        new_value = value_record.ruby_value
        changes[field.name] = { from: old_value, to: new_value } unless new_value == old_value
      end
      changes
    end
end
