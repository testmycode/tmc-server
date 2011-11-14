require 'rest_client'

# A remote machine running the tmc-sandbox web service
class RemoteSandbox
  include Rails.application.routes.url_helpers

  def initialize(url)
    @url = url
  end
  
  def self.random
    self.all.shuffle.first
  end
  
  def send_submission(submission, notify_url)
    raise "Exercise #{submission.exercise_name} for submission gone. Cannot resubmit." if submission.exercise == nil
    
    Dir.mktmpdir do |tmpdir|
      zip_path = "#{tmpdir}/submission.zip"
      tar_path = "#{tmpdir}/submission.tar"
      File.open(zip_path, 'wb') {|f| f.write(submission.return_file) }
      SubmissionPackager.new.package_submission(submission.exercise, zip_path, tar_path)
      
      File.open(tar_path) do |tar_file|
        RestClient.post @url, :file => tar_file, :notify => notify_url
      end
    end
  end

  def self.all
    SiteSetting.value('remote_sandboxes').map {|url| RemoteSandbox.new(url)}
  end
end
