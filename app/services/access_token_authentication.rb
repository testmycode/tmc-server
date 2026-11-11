# typed: strict
# frozen_string_literal: true

# Resolves the user behind a Doorkeeper access token, for every endpoint that accepts one.
module AccessTokenAuthentication
  extend T::Sig

  # Marks tokens issued by Api::V8::Application::UserAccessTokensController.
  HANDOFF_SCOPE = 'handoff'
  # Lets a client_credentials token call Api::V8::Application::UserAccessTokensController.
  ISSUER_SCOPE = 'issue_user_access_tokens'

  # The token's owner, or nil when the token is missing, revoked or expired, has no owner, or is a
  # handoff token of a user who became privileged after it was issued.
  sig { params(token: T.nilable(Doorkeeper::AccessToken)).returns(T.nilable(User)) }
  def self.user_for(token)
    return nil unless token&.accessible?

    user = User.find_by(id: token.resource_owner_id)
    user unless user.nil? || (handoff?(token) && user.privileged?)
  end

  # Revokes the user's handoff tokens, for when the user becomes privileged: endpoints such as
  # /oauth/token/info only check revocation, not user_for.
  sig { params(user: User).void }
  def self.revoke_handoff_tokens(user)
    Doorkeeper::AccessToken
      .where(resource_owner_id: user.id, revoked_at: nil)
      .where("? = ANY(string_to_array(scopes, ' '))", HANDOFF_SCOPE)
      .update_all(revoked_at: Time.current)
  end

  # Whether the token lets its client call UserAccessTokensController; the client still has to be
  # an allow-listed issuer.
  sig { params(token: Doorkeeper::AccessToken).returns(T::Boolean) }
  def self.issuer_token?(token)
    token.resource_owner_id.nil? && token.acceptable?([ISSUER_SCOPE])
  end

  # Whether UserAccessTokensController issued the token.
  sig { params(token: Doorkeeper::AccessToken).returns(T::Boolean) }
  def self.handoff?(token)
    token.includes_scope?(HANDOFF_SCOPE)
  end

  # Uids of the Doorkeeper applications allowed to issue tokens.
  sig { returns(T::Array[String]) }
  def self.issuer_application_uids
    T.let(Rails.configuration.x.user_access_token_issuer_application_uids, T::Array[String])
  end

  # Uid of the Doorkeeper application that issued tokens belong to.
  sig { returns(T.nilable(String)) }
  def self.target_application_uid
    T.let(Rails.configuration.x.user_access_token_target_application_uid, T.nilable(String))
  end
end
