class Api::Beta::DemoController < Api::Beta::BaseController

#    skip_before_action :doorkeeper_authorize!
  before_action :doorkeeper_authorize!, only: [:index], :scopes => [:public]
#  before_action :doorkeeper_authorize!


  def index
    present({'a' => "asd", "user" => current_user.inspect})
  end
end
