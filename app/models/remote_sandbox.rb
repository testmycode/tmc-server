# typed: strict
# frozen_string_literal: true

require 'rest-client'
require 'submission_packager'
require 'timeout'
require 'rust_langs_cli_executor'

SUBMISSION_PACKAGING_TIMEOUT_SECONDS = 10

# Represents a connection to a remote machine running the tmc-sandbox web service.
#
# These are transient objects read from the configuration file.
class RemoteSandbox
  extend T::Sig
  sig { returns(String) }
  attr_reader :baseurl

  # object is the sandbox's JSON error payload.
  class InternalSandboxError < StandardError
    extend T::Sig
    sig { returns(T.untyped) }
    attr_reader :object

    sig { params(object: T.untyped).void }
    def initialize(object)
      super()
      @object = object
    end
  end

  class SandboxUnavailableError < StandardError; end

  sig { params(baseurl: String, experimental: T::Boolean).void }
  def initialize(baseurl, experimental = true)
    @baseurl = baseurl
    @baseurl = @baseurl.gsub(/\/+$/, '')
    @experimental = experimental
    @capacity = T.let(nil, T.nilable(Integer))
    @parsed = T.let(nil, T.untyped)
  end

  sig { params(submission: Submission, notify_url: String).returns(T::Boolean) }
  def self.try_to_send_submission_to_free_server(submission, notify_url)
    # dir = ExerciseDir.get(submission.exercise.clone_path)
    # servers = if submission.exercise && dir.safe_for_experimental_sandbox
    #   if dir.type == 'java_maven'
    #     all_experimental.shuffle
    #   else
    #     all_experimental.shuffle + all.shuffle
    #   end
    # else
    #   all.shuffle
    # end
    servers = all.shuffle
    for server in servers # could be smarter about this
      begin
        server.send_submission(submission, notify_url)
      rescue SandboxUnavailableError => e
        Rails.logger.warn e
        # ignore
      else
        Rails.logger.info "Submission #{submission.id} sent to remote sandbox at #{server.baseurl}"
        Rails.logger.debug "Notify url: #{notify_url}"
        return true
      end
    end
    Rails.logger.warn 'No free server to send submission to. Leaving to reprocessor daemon.'
    false
  end

  sig { params(submission: Submission, notify_url: String).void }
  def send_submission(submission, notify_url)
    exercise = submission.exercise

    raise 'Submission has no secret token' if submission.secret_token.blank?
    raise "Exercise #{submission.exercise_name} for submission gone. Cannot resubmit." if exercise.nil?

    Dir.mktmpdir do |tmpdir|
      zip_path = "#{tmpdir}/submission.zip"
      tar_path = "#{tmpdir}/submission.tar"
      File.open(zip_path, 'wb') { |f| f.write(submission.return_file) }

      begin
        Timeout.timeout(SUBMISSION_PACKAGING_TIMEOUT_SECONDS) do
          RustLangsCliExecutor.prepare_submission(exercise.clone_path, tar_path, zip_path, {}, no_archive_prefix: true)
        end
      rescue Timeout::Error
        Rails.logger.error("RustLangsCliExecutor.prepare_submission timed out after #{SUBMISSION_PACKAGING_TIMEOUT_SECONDS} seconds for submission #{submission.id}")
        submission.pretest_error = 'Packaging submission took too long. Please make sure your submission is not too large or has too large files, or too many files.'
        submission.processed = true
        submission.save!
        next
      end

      File.open(tar_path, 'r') do |tar_file|
        Rails.logger.info "Posting submission to #{post_url}"
        # While Timeout::timeout is considered dangerous, this is still necessary because if this happens to block it will bring the whole server down.
        Timeout.timeout(10) do
          # The timeout is only for open_timeout and read_timeout
          payload = T.let({
            file: tar_file, notify: notify_url, token: submission.secret_token, submission_id: submission.id
          }, T::Hash[Symbol, T.untyped])
          payload[:docker_image] = exercise.docker_image if exercise.docker_image
          payload[:memory_limit_gb] = exercise.memory_limit_gb if exercise.memory_limit_gb
          payload[:cpu_limit] = exercise.cpu_limit if exercise.cpu_limit

          RestClient::Request.execute(method: :post, url: post_url, timeout: 5, payload: payload)
        end
        submission.sandbox = post_url
        submission.save!
      rescue StandardError => e
        puts e
        begin
          # Try to parse the response to see if the error originated from within the sandbox.
          raise SandboxUnavailableError unless e.is_a?(RestClient::Exception)
          @parsed = JSON.parse e.response
        rescue StandardError
          raise SandboxUnavailableError
        end
        if @parsed['status']
          # If sandbox returns status key, it is busy and unavailable.
          raise SandboxUnavailableError
        end
        raise InternalSandboxError.new(@parsed['error'])
      end
    rescue SandboxUnavailableError
      raise
    rescue InternalSandboxError => e
      submission.pretest_error = e.object
      submission.save!
      raise
    rescue StandardError
      Rails.logger.info "Submission #{submission.id} could not be packaged: #{Regexp.last_match(1)}"
      Rails.logger.info "Marking submission #{submission.id} as failed."
      submission.pretest_error = 'Failed to process submission. Likely sent in incorrect format.'
      submission.processed = true
      submission.save!
      raise
    end
  end

  sig { returns(T::Array[RemoteSandbox]) }
  def self.all
    @all ||= T.let(SiteSetting.value('remote_sandboxes').map { |url| RemoteSandbox.new(url) }, T.nilable(T::Array[RemoteSandbox]))
  end

  sig { returns(T::Array[RemoteSandbox]) }
  def self.all_experimental
    @all_experimental ||= T.let(SiteSetting.value('experimental_sandboxes').map { |url| RemoteSandbox.new(url, true) }, T.nilable(T::Array[RemoteSandbox]))
  end

  sig { returns(Integer) }
  def self.total_capacity
    all.map(&:capacity).reduce(0, &:+)
  end

  sig { returns(Integer) }
  def capacity
    @capacity ||= begin
      status_count('total_instances')
    rescue StandardError
      nil
    end
    @capacity || 0
  end

  # nil when the status lacks an integer count; 0 when the sandbox is unreachable.
  sig { returns(T.nilable(Integer)) }
  def busy_instances
    status_count('busy_instances')
  rescue StandardError
    0
  end

  private
    # Polled every second, so a malformed status yields nil instead of a logged type error.
    sig { params(key: String).returns(T.nilable(Integer)) }
    def status_count(key)
      count = get_status[key]
      count if count.is_a?(Integer)
    end

    sig { returns(T.untyped) }
    def get_status
      ActiveSupport::JSON.decode(RestClient.get(status_url))
    end

    sig { returns(String) }
    def post_url
      "#{@baseurl}/tasks.json"
    end

    sig { returns(String) }
    def status_url
      "#{@baseurl}/status.json"
    end
end
