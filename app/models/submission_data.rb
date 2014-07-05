# Stores large data such as the returned ZIP and compressed I/O logs for a submission.
#
# In addition to good old separation of concerns, it is useful to force these to be
# loaded explicitly. If these fields were directly in Submission, a result set
# (with default configuration) of Submission objects would easily consume quite a bit of memory.
class SubmissionData < ActiveRecord::Base
  self.primary_key = 'submission_id'

  belongs_to :submission

  def stdout
    @stdout ||=
      if stdout_compressed != nil
        uncompress(stdout_compressed)
      else
        nil
      end
  end

  def stdout=(value)
    if value != nil
      self.stdout_compressed = compress(value)
    else
      self.stdout_compressed = nil
    end
    @stdout = value
  end

  def stderr
    @stderr ||=
      if stderr_compressed != nil
        uncompress(stderr_compressed)
      else
        nil
      end
  end

  def stderr=(value)
    if value != nil
      self.stderr_compressed = compress(value)
    else
      self.stderr_compressed = nil
    end
    @stderr = value
  end

  def vm_log
    @vm_log ||=
      if vm_log_compressed != nil
        uncompress(vm_log_compressed)
      else
        nil
      end
  end

  def vm_log=(value)
    if value != nil
      self.vm_log_compressed = compress(value)
    else
      self.vm_log_compressed = nil
    end
    @vm_log = value
  end

  def valgrind
    @valgrind ||=
      if valgrind_compressed != nil
        uncompress(valgrind_compressed)
      else
        nil
      end
  end

  def valgrind=(value)
    if value != nil
      self.valgrind_compressed = compress(value)
    else
      self.valgrind_compressed = nil
    end
    @valgrind = value
  end

  def validations
    @validations ||=
      if validations_compressed != nil
        uncompress(validations_compressed)
      else
        nil
      end
  end

  def validations=(value)
    if value != nil
      self.validations_compressed = compress(value)
    else
      self.validations_compressed = nil
    end
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
