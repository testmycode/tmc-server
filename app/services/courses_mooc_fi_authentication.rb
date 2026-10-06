# frozen_string_literal: true

# Resolves the local user behind a courses.mooc.fi access token sent to API v8.
module CoursesMoocFiAuthentication
  # Returns the user the request's bearer token belongs to, or nil when there is no bearer token,
  # courses.mooc.fi rejects it, or it belongs to no local user. Raises
  # CoursesMoocFiTokenIntrospector::Unavailable when the token cannot be checked right now.
  def self.user_for(request)
    token = Doorkeeper::OAuth::Token.from_bearer_authorization(request)
    return nil if token.blank?

    result = CoursesMoocFiTokenIntrospector.introspect(token)
    return nil unless result

    User.find_by(courses_mooc_fi_user_id: result.sub) || link_by_upstream_id(result)
  end

  # Binds the user with the TMC id courses.mooc.fi reports to the token's subject, unless that user
  # is already bound to another subject.
  def self.link_by_upstream_id(result)
    return nil if result.upstream_id.blank?

    user = User.find_by(id: result.upstream_id)
    return nil unless user
    return user if user.courses_mooc_fi_user_id&.casecmp?(result.sub)

    if user.courses_mooc_fi_user_id.present?
      Rails.logger.warn("courses.mooc.fi upstream_id #{result.upstream_id} maps to user #{user.id}, which is bound to a different courses_mooc_fi_user_id; refusing")
      return nil
    end

    # Skips validation; the introspector has already checked that sub is a UUID.
    user.update_column(:courses_mooc_fi_user_id, result.sub)
    user
  rescue ActiveRecord::RecordNotUnique
    # A concurrent request bound the subject first.
    User.find_by(courses_mooc_fi_user_id: result.sub)
  end
  private_class_method :link_by_upstream_id
end
