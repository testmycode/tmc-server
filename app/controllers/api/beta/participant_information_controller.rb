class Api::Beta::DemoController < Api::Beta::BaseController
  before_action :doorkeeper_authorize!, only: [:index], :scopes => [:public]

  def index
    present({'a' => "asd", "user" => current_user.inspect})
  end
end

