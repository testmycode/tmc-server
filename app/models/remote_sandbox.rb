# frozen_string_literal: true

require 'rest_client'
require 'submission_packager'
require 'timeout'
require 'rust_langs_cli_executor'

# Represents a connection to a remote machine running the tmc-sandbox web service.
#
# These are transient objects read from the configuration file.
class RemoteSandbox
  attr_reader :baseurl

  class SandboxUnavailableError < StandardError; end

  def initialize(baseurl, experimental = false)
    @baseurl = baseurl
    @baseurl = @baseurl.gsub(/\/+$/, '')
    @experimental = experimental
  end

  def self.try_to_send_submission_to_free_server(submission, notify_url)
    dir = ExerciseDir.get(submission.exercise.clone_path)
    servers = if submission.exercise && dir.safe_for_experimental_sandbox
      if dir.type == 'java_maven'
        all_experimental.shuffle
      else
        all_experimental.shuffle + all.shuffle
      end
    else
      all.shuffle
    end
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

  def send_submission(submission, notify_url)
    exercise = submission.exercise

    raise 'Submission has no secret token' if submission.secret_token.blank?
    raise "Exercise #{submission.exercise_name} for submission gone. Cannot resubmit." if exercise.nil?

    Dir.mktmpdir do |tmpdir|
      zip_path = "#{tmpdir}/submission.zip"
      tar_path = "#{tmpdir}/submission.tar"
      File.open(zip_path, 'wb') { |f| f.write(submission.return_file) }
      RustLangsCliExecutor.prepare_submission(submission.exercise.clone_path, tar_path, zip_path) if exercise.docker_image
      SubmissionPackager.get(exercise).package_submission(exercise, zip_path, tar_path, submission.params, include_tmc_langs: !@experimental) unless exercise.docker_image

      File.open(tar_path, 'r') do |tar_file|
        Rails.logger.info "Posting submission to #{post_url}"
        # While Timeout::timeout is considered dangerous, this is still necessary because if this happens to block it will bring the whole server down.
        Timeout.timeout(10) do
          # The timeout is only for open_timeout and read_timeout
          payload = {
            file: tar_file, notify: notify_url, token: submission.secret_token
          }
          payload[:docker_image] = exercise.docker_image if exercise.docker_image

          RestClient::Request.execute(method: :post, url: post_url, timeout: 5, payload: payload)
        end
        submission.sandbox = post_url
        submission.save!
      rescue StandardError => e
        puts e
        raise SandboxUnavailableError
      end
    rescue SandboxUnavailableError
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

  def try_to_seed_maven_cache(file_path)
    seed_maven_cache(file_path)
  rescue StandardError
    Rails.logger.warn "Failed to seed maven cache: #{$!}"
  end

  def seed_maven_cache(file_path)
    File.open(file_path, 'r') do |file|
      RestClient.post(maven_cache_populate_url, file: file, run_tests: true)
    end
  end

  def self.all
    @all ||= SiteSetting.value('remote_sandboxes').map { |url| RemoteSandbox.new(url) }
  end

  def self.all_experimental
    @all_experimental ||= SiteSetting.value('experimental_sandboxes').map { |url| RemoteSandbox.new(url, true) }
  end

  def self.total_capacity
    all.map(&:capacity).reduce(0, &:+)
  end

  def capacity
    @capacity ||= begin
      get_status['total_instances']
    rescue StandardError
      nil
    end
    @capacity || 0
  end

  def busy_instances
    get_status['busy_instances']
  rescue StandardError
    0
  end

  private

    def get_status
      ActiveSupport::JSON.decode(RestClient.get(status_url))
    end

    def post_url
      "#{@baseurl}/tasks.json"
    end

    def status_url
      "#{@baseurl}/status.json"
    end

    def maven_cache_populate_url
      "#{@baseurl}/maven_cache/populate.json"
    end
end
