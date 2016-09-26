class Setup::StartController < Setup::SetupController
  skip_authorization_check only: [:index]

  def index
    @my_organizations = Organization.taught_organizations(current_user)
    @organization = @my_organizations.first if @my_organizations.count == 1
  end
end
