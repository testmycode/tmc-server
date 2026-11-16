# typed: strict
# frozen_string_literal: true

# The email and password fields of the account form, which both the user's own account page and
# the participant settings page submit.
module AccountCredentialsForm
  extend T::Sig
  extend ActiveSupport::Concern
  extend T::Helpers
  requires_ancestor { ApplicationController }

  CREDENTIAL_FIELDS = T.let(%w[email email_repeat old_password password password_repeat].freeze, T::Array[String])

  private
    sig { params(user: User, user_params: T.untyped).void }
    def set_email(user, user_params)
      return if user.managed_externally?
      return if !user.new_record? && user_params[:email_repeat].blank?

      if user_params[:email].blank?
        user.errors.add(:email, 'needed')
      elsif user_params[:email] != user_params[:email_repeat]
        user.errors.add(:email_repeat, 'did not match')
      else
        user.email = user_params[:email].strip
      end
    end

    # A managed account's form has no credential fields, so any submitted come from a stale page.
    sig { params(user: User, user_params: T.untyped).void }
    def refuse_managed_credential_changes(user, user_params)
      return unless user.managed_externally?
      return if CREDENTIAL_FIELDS.none? { |field| user_params[field].present? }

      user.errors.add(:base, User::MANAGED_CREDENTIALS_MESSAGE)
    end

    sig { params(user: User, user_params: T.untyped).returns(T::Boolean) }
    def maybe_update_password(user, user_params)
      return false if user.managed_externally?

      if user_params[:old_password].present? || user_params[:password].present?
        if user.externally_managed_without_target?
          user.errors.add(:base, 'This account is being migrated; password changes are temporarily unavailable.')
          return false
        end
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
end
