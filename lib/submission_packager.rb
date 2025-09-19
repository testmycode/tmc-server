# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'rust_langs_cli_executor'

SUBMISSION_PACKAGING_TIMEOUT_SECONDS = 10

# Takes a submission zip and makes a tar file suitable for the sandbox
class SubmissionPackager
  # Packages a submitted ZIP of the given exercise into a TAR or a ZIP with tests
  # added from the clone (to ensure they haven't been tampered with).
  #
  # - zip_path must be the path to the submitted zip.
  # - return_file_path is the path to the file to be generated.
  # - extra_params are written as shell export statements into into .tmcparams.
  # - config options:
  #   - tests_from_stub: includes tests from the stub instead of the clone.
  #                      This effectively excludes hidden tests.
  #   - include_ide_files: includes IDE settings from the submission,
  #                        or from the clone if none in the submission
  #                        (as is usually the case).
  #   - no_tmc_run: does not include the tmc-run file
  #   - format: may be set to :zip to get a zip file. Defaults to :tar.
  #   - toplevel_dir_name: if present, the zip or tar is made such that
  #                        there is a toplevel directory with this name

  def get_full_zip(submission, toplevel_dir_name)
    Dir.mktmpdir do |tmpdir|
      zip_path = "#{tmpdir}/submission.zip"
      return_zip_path = "#{tmpdir}/submission_to_be_returned.zip"
      File.open(zip_path, 'wb') { |f| f.write(submission.return_file) }
      begin
        Timeout.timeout(SUBMISSION_PACKAGING_TIMEOUT_SECONDS) do
          RustLangsCliExecutor.prepare_submission(submission.exercise.clone_path, return_zip_path, zip_path, submission.params,
                                                  tests_from_stub: submission.exercise.stub_zip_file_path,
                                                  format: :zip,
                                                  toplevel_dir_name: toplevel_dir_name)
        end
      rescue Timeout::Error
        Rails.logger.error("RustLangsCliExecutor.prepare_submission timed out after #{SUBMISSION_PACKAGING_TIMEOUT_SECONDS} seconds for submission #{submission.id} in SubmissionPackager")
        raise "Submission preparation timed out after #{SUBMISSION_PACKAGING_TIMEOUT_SECONDS} seconds. Please try again."
      end
      File.read(return_zip_path)
    end
  end
end
