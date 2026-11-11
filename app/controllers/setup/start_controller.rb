# typed: strict
# frozen_string_literal: true

class Setup::StartController < Setup::SetupController
  extend T::Sig
  skip_authorization_check only: [:index]

  sig { void }
  def index
    my_organizations = Organization.taught_organizations(current_user)
    @my_organizations = T.let(my_organizations, T.nilable(ActiveRecord::Relation))
    @organization = my_organizations.first if my_organizations.count == 1
  end
end
