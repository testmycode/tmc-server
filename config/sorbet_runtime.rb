# typed: strict
# frozen_string_literal: true

# Production only: reports sorbet-runtime violations instead of raising (except T.must), so a wrong sig can't take the site down.
# Required from config/application.rb to cover boot.
module SorbetRuntimeReporting
  extend T::Sig

  # Bounds memory; once full the set restarts, so a location can be reported again.
  MAX_REPORTED_LOCATIONS = 1000
  MUST_KINDS = T.let(['T.must', 'T.must_because'].freeze, T::Array[String])
  RUNTIME_GEM_DIR = T.let(Gem.loaded_specs['sorbet-runtime']&.full_gem_path, T.nilable(String))

  @reported_locations = T.let(Set.new, T::Set[String])
  @reported_locations_mutex = T.let(Mutex.new, Thread::Mutex)

  # Logs and notifies NewRelic once per process per location, so a wrong sig on a per-row method can't flood the logs.
  sig { params(error: Exception, location: T.nilable(String)).void }
  def self.report(error, location)
    log(error) if first_report_at?(location || error.message)
  end

  sig { params(error: Exception).void }
  def self.log(error)
    backtrace = error.backtrace || []
    # Both are nil until the application has initialized.
    root = T.let(Rails.root, T.nilable(Pathname))
    logger = T.let(Rails.logger, T.nilable(ActiveSupport::BroadcastLogger))
    cleaned_backtrace = root ? Rails.backtrace_cleaner.clean(backtrace) : backtrace
    cleaned_backtrace = backtrace if cleaned_backtrace.empty?
    message = "#{error.class}: #{error.message}\n#{cleaned_backtrace.join("\n")}"
    logger ? logger.error(message) : warn(message)
    # Expected: execution continues, so the request itself has not failed.
    NewRelic::Agent.notice_error(error, expected: true) if defined?(NewRelic::Agent)
  end

  # The first frame outside sorbet-runtime, as "path:line".
  sig { params(error: Exception).returns(T.nilable(String)) }
  def self.origin(error)
    runtime_gem_dir = RUNTIME_GEM_DIR
    frame = error.backtrace_locations&.find { |location| !runtime_gem_dir || !location.path.to_s.start_with?(runtime_gem_dir) }
    frame && "#{frame.path}:#{frame.lineno}"
  end

  # Makes violations log instead of raise. T.must still raises, so the error names the line that got nil
  # instead of a later NoMethodError.
  sig { void }
  def self.install_production_handlers!
    T::Configuration.exclude_value_in_type_errors

    T::Configuration.call_validation_error_handler = lambda do |signature, opts|
      caller_location = opts[:location]
      location = "#{signature.method_name}@#{caller_location&.path}:#{caller_location&.lineno}"
      # Checked first: building the error (backtrace) is the expensive part.
      next unless first_report_at?(location)

      error = TypeError.new(opts[:pretty_message])
      error.set_backtrace(caller)
      log(error)
    end

    T::Configuration.inline_type_error_handler = lambda do |error, opts|
      raise error if MUST_KINDS.include?(opts[:kind])
      report(error, origin(error))
    end

    T::Configuration.sig_validation_error_handler = lambda do |error, opts|
      report(error, opts[:method]&.source_location&.join(':'))
    end

    # The method then runs unchecked.
    T::Configuration.sig_builder_error_handler = lambda do |error, location|
      report(error, location ? "#{location.path}:#{location.lineno}" : nil)
    end
  end

  sig { params(location: String).returns(T::Boolean) }
  def self.first_report_at?(location)
    @reported_locations_mutex.synchronize do
      @reported_locations.clear if @reported_locations.size >= MAX_REPORTED_LOCATIONS
      !@reported_locations.add?(location).nil?
    end
  end
  private_class_method :first_report_at?, :log
end

SorbetRuntimeReporting.install_production_handlers! if Rails.env.production?
