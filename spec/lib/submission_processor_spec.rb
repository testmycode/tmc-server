require 'spec_helper'

describe SubmissionProcessor do

  def expect_processing
    expect(RemoteSandbox).to receive(:try_to_send_submission_to_free_server).with(@sub, @sub.result_url)
  end

  def expect_no_processing
    expect(RemoteSandbox).not_to receive(:try_to_send_submission_to_free_server)
  end

  describe "reprocessing submissions" do

    before :each do
      @sub = FactoryGirl.create(:submission, processed: false)
    end

    it "should reprocess when no sandbox was available a short while ago" do
      @sub.processing_tried_at = Time.now - Submission.processing_retry_interval - 1.second
      @sub.save!
      expect_processing
      SubmissionProcessor.new.reprocess_timed_out_submissions
    end

    it "should not reprocess when processing was just attempted" do
      @sub.processing_tried_at = Time.now
      @sub.save!
      expect_no_processing
      SubmissionProcessor.new.reprocess_timed_out_submissions
    end

    it "should reprocess even if a sandbox has received the job a long time ago" do
      @sub.processing_tried_at = Time.now - Submission.processing_retry_interval - 1.second
      @sub.processing_began_at = Time.now - Submission.processing_resend_interval - 1.second
      @sub.save!
      expect_processing
      SubmissionProcessor.new.reprocess_timed_out_submissions
    end

    it "should not reprocess when a sandbox has received the job a reasonable time ago" do
      @sub.processing_tried_at = Time.now - Submission.processing_retry_interval - 1.second
      @sub.processing_began_at = Time.now - Submission.processing_resend_interval + 5.seconds
      expect(@sub.processing_began_at).to be < @sub.processing_tried_at
      @sub.save!
      expect_no_processing
      SubmissionProcessor.new.reprocess_timed_out_submissions
    end

    context "when the submission has been reprocessed too many times" do
      before :each do
        @sub.times_sent_to_sandbox =  Submission.max_attempts_at_processing
        @sub.save!
      end

      it "should not reprocess it any more" do
        expect_no_processing
        SubmissionProcessor.new.reprocess_timed_out_submissions
      end
      it "should mark it as processed and having an error" do
        SubmissionProcessor.new.reprocess_timed_out_submissions
        @sub.reload
        expect(@sub).to be_processed
        expect(@sub.pretest_error).not_to be_empty
        expect(@sub.secret_token).to be_nil
        expect(@sub.status).to eq(:error)
      end
    end

    context "when a sandbox receives the job" do
      before :each do
        expect(RemoteSandbox).to receive(:try_to_send_submission_to_free_server).and_return(true)
      end

      it "should increment the times-sent-to-sandbox counter" do
        original_count = Submission.max_attempts_at_processing - 1
        @sub.times_sent_to_sandbox = original_count
        @sub.save!
        SubmissionProcessor.new.reprocess_timed_out_submissions
        @sub.reload
        expect(@sub.times_sent_to_sandbox).to eq(original_count + 1)
      end

      it "should update the processing_tried_at and processing_began_at timestamps" do
        SubmissionProcessor.new.reprocess_timed_out_submissions
        @sub.reload
        expect(@sub.processing_tried_at).to be > Time.now - 5.seconds
        expect(@sub.processing_began_at).to be > Time.now - 5.seconds
      end
    end

    context "when no sandbox receives the job" do
      before :each do
        expect(RemoteSandbox).to receive(:try_to_send_submission_to_free_server).and_return(false)
      end

      it "should not increment the times-sent-to-sandbox counter" do
        original_count = Submission.max_attempts_at_processing - 1
        @sub.times_sent_to_sandbox = original_count
        @sub.save!
        SubmissionProcessor.new.reprocess_timed_out_submissions
        @sub.reload
        expect(@sub.times_sent_to_sandbox).to eq(original_count)
      end

      it "should update the processing_tried_at timestamp but not processing_began_at" do
        SubmissionProcessor.new.reprocess_timed_out_submissions
        @sub.reload
        expect(@sub.processing_tried_at).to be > Time.now - 5.seconds
        expect(@sub.processing_began_at).to be_nil
      end
    end
  end
end
