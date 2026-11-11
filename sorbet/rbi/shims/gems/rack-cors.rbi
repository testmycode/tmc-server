# typed: true

class Rack::Cors
  sig { params(block: T.proc.bind(Rack::Cors::Resources).void).returns(T.untyped) }
  def allow(&block); end
end
