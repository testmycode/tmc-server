class SubmissionData < ActiveRecord::Base
  set_primary_key :submission_id

  belongs_to :submission

  def stdout
    @stdout ||=
      if stdout_compressed != nil
        Zlib::Inflate.inflate(stdout_compressed)
      else
        nil
      end
  end

  def stdout=(value)
    if value != nil
      self.stdout_compressed = Zlib::Deflate.deflate(value)
    else
      self.stdout_compressed = nil
    end
    @stdout = value
  end

  def stderr
    @stderr ||=
      if stderr_compressed != nil
        Zlib::Inflate.inflate(stderr_compressed)
      else
        nil
      end
  end

  def stderr=(value)
    if value != nil
      self.stderr_compressed = Zlib::Deflate.deflate(value)
    else
      self.stderr_compressed = nil
    end
    @stderr = value
  end
end