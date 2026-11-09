# typed: true

# DO NOT EDIT MANUALLY
# This file was pulled from a central RBI files repository.
# Please run `bin/tapioca annotations` to update it.

module Faraday
  class << self
    sig { params(url: T.untyped, options: T::Hash[Symbol, T.untyped], block: T.nilable(T.proc.params(connection: Faraday::Connection).void)).returns(Faraday::Connection) }
    def new(url = nil, options = {}, &block); end

    # @method_missing: proxied to Faraday.default_connection, a Faraday::Connection
    sig { params(url: T.nilable(T.any(String, URI::Generic)), params: T.nilable(T::Hash[T.untyped, T.untyped]), headers: T.nilable(T::Hash[T.untyped, T.untyped]), block: T.nilable(T.proc.params(request: Faraday::Request).void)).returns(Faraday::Response) }
    def get(url = nil, params = nil, headers = nil, &block); end

    # @method_missing: proxied to Faraday.default_connection, a Faraday::Connection
    sig { params(url: T.nilable(T.any(String, URI::Generic)), params: T.nilable(T::Hash[T.untyped, T.untyped]), headers: T.nilable(T::Hash[T.untyped, T.untyped]), block: T.nilable(T.proc.params(request: Faraday::Request).void)).returns(Faraday::Response) }
    def head(url = nil, params = nil, headers = nil, &block); end

    # @method_missing: proxied to Faraday.default_connection, a Faraday::Connection
    sig { params(url: T.nilable(T.any(String, URI::Generic)), params: T.nilable(T::Hash[T.untyped, T.untyped]), headers: T.nilable(T::Hash[T.untyped, T.untyped]), block: T.nilable(T.proc.params(request: Faraday::Request).void)).returns(Faraday::Response) }
    def delete(url = nil, params = nil, headers = nil, &block); end

    # @method_missing: proxied to Faraday.default_connection, a Faraday::Connection
    sig { params(url: T.nilable(T.any(String, URI::Generic)), params: T.nilable(T::Hash[T.untyped, T.untyped]), headers: T.nilable(T::Hash[T.untyped, T.untyped]), block: T.nilable(T.proc.params(request: Faraday::Request).void)).returns(Faraday::Response) }
    def trace(url = nil, params = nil, headers = nil, &block); end

    # @method_missing: proxied to Faraday.default_connection, a Faraday::Connection
    sig { params(url: T.nilable(T.any(String, URI::Generic)), body: T.untyped, headers: T.nilable(T::Hash[T.untyped, T.untyped]), block: T.nilable(T.proc.params(request: Faraday::Request).void)).returns(Faraday::Response) }
    def post(url = nil, body = nil, headers = nil, &block); end

    # @method_missing: proxied to Faraday.default_connection, a Faraday::Connection
    sig { params(url: T.nilable(T.any(String, URI::Generic)), body: T.untyped, headers: T.nilable(T::Hash[T.untyped, T.untyped]), block: T.nilable(T.proc.params(request: Faraday::Request).void)).returns(Faraday::Response) }
    def put(url = nil, body = nil, headers = nil, &block); end

    # @method_missing: proxied to Faraday.default_connection, a Faraday::Connection
    sig { params(url: T.nilable(T.any(String, URI::Generic)), body: T.untyped, headers: T.nilable(T::Hash[T.untyped, T.untyped]), block: T.nilable(T.proc.params(request: Faraday::Request).void)).returns(Faraday::Response) }
    def patch(url = nil, body = nil, headers = nil, &block); end
  end
end

class Faraday::Response
  sig { returns(T::Boolean) }
  def success?; end
end
