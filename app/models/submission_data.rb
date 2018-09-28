# frozen_string_literal: true

# Stores large data such as the returned ZIP and compressed I/O logs for a submission.
#
# In addition to good old separation of concerns, it is useful to force these to be
# loaded explicitly. If these fields were directly in Submission, a result set
# (with default configuration) of Submission objects would easily consume quite a bit of memory.
class SubmissionData < ActiveRecord::Base
  self.primary_key = 'submission_id'

  belongs_to :submission

  def stdout
    unless stdout_compressed.nil?
      @stdout ||=
        uncompress(stdout_compressed)
    end
  end

  def stdout=(value)
    self.stdout_compressed = (compress(value) unless value.nil?)
    @stdout = value
  end

  def stderr
    unless stderr_compressed.nil?
      @stderr ||=
        uncompress(stderr_compressed)
    end
  end

  def stderr=(value)
    self.stderr_compressed = (compress(value) unless value.nil?)
    @stderr = value
  end

  def vm_log
    unless vm_log_compressed.nil?
      @vm_log ||=
        uncompress(vm_log_compressed)
    end
  end

  def vm_log=(value)
    self.vm_log_compressed = (compress(value) unless value.nil?)
    @vm_log = value
  end

  def valgrind
    unless valgrind_compressed.nil?
      @valgrind ||=
        uncompress(valgrind_compressed)
    end
  end

  def valgrind=(value)
    self.valgrind_compressed = (compress(value) unless value.nil?)
    @valgrind = value
  end

  def validations
    unless validations_compressed.nil?
      @validations ||=
        uncompress(validations_compressed)
    end
  end

  def validations=(value)
    self.validations_compressed = (compress(value) unless value.nil?)
    @validations = value
  end

  private

  def compress(text)
    Zlib::Deflate.deflate(text)
  end

  def uncompress(compressed_text)
    Zlib::Inflate.inflate(compressed_text).force_encoding('UTF-8')
  end
end
