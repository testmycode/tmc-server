# typed: true

# Doorkeeper instance_evals the configure block on a builder and the callbacks in its controllers.

module Doorkeeper
  class << self
    sig { params(block: T.proc.bind(Doorkeeper::Config::Builder).void).returns(T.untyped) }
    def configure(&block); end
  end
end

class Doorkeeper::Config::Builder
  sig { params(args: T.untyped, block: T.nilable(T.proc.bind(Doorkeeper::ApplicationController).returns(T.untyped))).returns(T.untyped) }
  def resource_owner_authenticator(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.bind(Doorkeeper::ApplicationController).returns(T.untyped))).returns(T.untyped) }
  def admin_authenticator(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.bind(Doorkeeper::ApplicationMetalController).params(routes: T.untyped).returns(T.untyped))).returns(T.untyped) }
  def resource_owner_from_credentials(*args, &block); end
end

module Doorkeeper::OpenidConnect
  class << self
    sig { params(block: T.proc.bind(Doorkeeper::OpenidConnect::Config::Builder).void).returns(T.untyped) }
    def configure(&block); end
  end
end

class Doorkeeper::OpenidConnect::Config::Builder
  sig { params(args: T.untyped, block: T.nilable(T.proc.bind(Doorkeeper::OpenidConnect::ClaimsBuilder).void)).returns(T.untyped) }
  def claims(*args, &block); end
end
