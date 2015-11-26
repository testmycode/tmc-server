require 'rest_client'
require 'submission_packager'

# Represents a connection to a remote machine running the tmc-sandbox web service.
#
# These are transient objects read from the configuration file.
class RemoteSandbox
  attr_reader :baseurl

  class SandboxUnavailableError < StandardError; end

  def initialize(baseurl)
    @baseurl = baseurl
    @baseurl = @baseurl.gsub(/\/+$/, '')
  end

  def self.try_to_send_submission_to_free_server(submission, notify_url)
    for server in all.shuffle # could be smarter about this
      begin
        server.send_submission(submission, notify_url)
      rescue SandboxUnavailableError
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

    fail 'Submission has no secret token' if submission.secret_token.blank?
    fail "Exercise #{submission.exercise_name} for submission gone. Cannot resubmit." if exercise.nil?

    Dir.mktmpdir do |tmpdir|
      begin
        zip_path = "#{tmpdir}/submission.zip"
        tar_path = "#{tmpdir}/submission.tar"
        File.open(zip_path, 'wb') { |f| f.write(submission.return_file) }
        SubmissionPackager.get(exercise).package_submission(exercise, zip_path, tar_path, submission.params)

        File.open(tar_path, 'r') do |tar_file|
          begin
            RestClient.post post_url, file: tar_file, notify: notify_url, token: submission.secret_token
            submission.sandbox = post_url
            submission.save!
          rescue
            raise SandboxUnavailableError.new
          end
        end
      rescue SandboxUnavailableError
        raise
      rescue
        Rails.logger.info "Submission #{submission.id} could not be packaged: #{$1}"
        Rails.logger.info "Marking submission #{submission.id} as failed."
        submission.pretest_error = 'Failed to process submission. Likely sent in incorrect format.'
        submission.processed = true
        submission.save!
        raise
      end
    end
  end

  def try_to_seed_maven_cache(file_path)
    seed_maven_cache(file_path)
  rescue
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

  def self.total_capacity
    all.map(&:capacity).reduce(0, &:+)
  end

  def capacity
    @capacity ||= begin
      get_status['total_instances']
    rescue
      nil
    end
    @capacity || 1
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
