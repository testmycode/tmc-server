class Setup::StartController < Setup::SetupController

  skip_authorization_check only: [:index]

  def index
    print_setup_breadcrumb(0)

    @my_organizations = Organization.taught_organizations(current_user)

    #TODO: only first org is chosen, should consider all, if user belongs to many
    @organization = @my_organizations.first

  end
end
