# frozen_string_literal: true

# Resolves the user behind a Doorkeeper access token, for every endpoint that accepts one.
module AccessTokenAuthentication
  # Marks tokens issued by Api::V8::Application::UserAccessTokensController.
  HANDOFF_SCOPE = 'handoff'
  # Lets a client_credentials token call Api::V8::Application::UserAccessTokensController.
  ISSUER_SCOPE = 'issue_user_access_tokens'

  # The token's owner, or nil when the token is revoked or expired, has no owner, or is a handoff
  # token of a user who became privileged after it was issued.
  def self.user_for(token)
    return nil unless token&.accessible?

    user = User.find_by(id: token.resource_owner_id)
    user unless user.nil? || (handoff?(token) && user.privileged?)
  end

  # Whether the token lets its client call UserAccessTokensController; the client still has to be
  # an allow-listed issuer.
  def self.issuer_token?(token)
    token.resource_owner_id.nil? && token.acceptable?([ISSUER_SCOPE])
  end

  def self.handoff?(token)
    token.includes_scope?(HANDOFF_SCOPE)
  end
end
