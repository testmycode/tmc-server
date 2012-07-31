require 'rest_client'
require 'submission_packager'

# A remote machine running the tmc-sandbox web service
class RemoteSandbox
  attr_reader :url

  class SandboxUnavailableError < StandardError; end

  def initialize(baseurl)
    @baseurl = baseurl
    @baseurl = @baseurl.gsub(/\/+$/, '')
  end
  
  def self.try_to_send_submission_to_free_server(submission, notify_url)
    for server in self.all.shuffle # could be smarter about this
      begin
        server.send_submission(submission, notify_url)
      rescue SandboxUnavailableError
        # ignore
      else
        Rails.logger.info "Submission #{submission.id} sent to remote sandbox at #{server.url}"
        Rails.logger.debug "Notify url: #{notify_url}"
        return true
      end
    end
    Rails.logger.warn "No free server to send submission to. Leaving to reprocessor daemon."
    false
  end
  
  def send_submission(submission, notify_url)
    exercise = submission.exercise

    raise "Submission has no secret token" if submission.secret_token.blank?
    raise "Exercise #{submission.exercise_name} for submission gone. Cannot resubmit." if exercise == nil
    
    Dir.mktmpdir do |tmpdir|
      begin
        zip_path = "#{tmpdir}/submission.zip"
        tar_path = "#{tmpdir}/submission.tar"
        File.open(zip_path, 'wb') {|f| f.write(submission.return_file) }
        SubmissionPackager.get(exercise).package_submission(exercise, zip_path, tar_path)

        File.open(tar_path) do |tar_file|
          begin
            RestClient.post post_url, :file => tar_file, :notify => notify_url, :token => submission.secret_token
          rescue
            raise SandboxUnavailableError.new
          end
        end
      rescue SandboxUnavailableError
        raise
      rescue
        Rails.logger.info "Submission #{submission.id} could not be packaged: #{$1}"
        Rails.logger.info "Marking submission #{submission.id} as failed."
        submission.pretest_error = "Failed to process submission. Likely sent in incorrect format."
        submission.processed = true
        submission.save!
        raise
      end
    end
  end

  def self.all
    SiteSetting.value('remote_sandboxes').map {|url| RemoteSandbox.new(url)}
  end

  def self.count
    SiteSetting.value('remote_sandboxes').size
  end


private
  def post_url
    "#{@baseurl}/tasks.json"
  end
end
