# typed: strict

# frozen_string_literal: true

class CanAccessPgHero
  extend T::Sig

  sig { params(request: ActionDispatch::Request).returns(T::Boolean) }
  def self.matches?(request)
    current_user = User.find_by(id: request.env['rack.session']['user_id'])
    return false if current_user.blank?
    Ability.new(current_user).can? :access_pghero, nil
  end
end
