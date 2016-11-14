module AuthorizedContentHelper
  # This method always returns safe collections so we can skip authorization
  def authorized_content(collection)
    self.class.skip_authorization_check
    authorized = collection.readable(current_user)
    raise CanCan::AccessDenied, 'You are not signed in!' if current_user.guest?
    authorized
  end
end
