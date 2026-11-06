# typed: true

module LogStasher
  # LogStasher instance_execs the block in whichever controller handles the request.
  sig { params(block: T.proc.bind(::ActionController::Metal).params(fields: T::Hash[Symbol, T.untyped]).void).returns(T.untyped) }
  def add_custom_fields(&block); end
end
