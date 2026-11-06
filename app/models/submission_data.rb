# typed: strict
# frozen_string_literal: true

# Stores large data such as the returned ZIP and compressed I/O logs for a submission.
#
# In addition to good old separation of concerns, it is useful to force these to be
# loaded explicitly. If these fields were directly in Submission, a result set
# (with default configuration) of Submission objects would easily consume quite a bit of memory.
class SubmissionData < ApplicationRecord
  extend T::Sig
  self.primary_key = 'submission_id'

  belongs_to :submission

  sig { returns(T.nilable(String)) }
  def stdout
    compressed = stdout_compressed
    unless compressed.nil?
      @stdout ||= T.let(uncompress(compressed), T.nilable(String))
    end
  end

  sig { params(value: T.nilable(String)).void }
  def stdout=(value)
    self.stdout_compressed = (compress(value) unless value.nil?)
    @stdout = T.let(value, T.nilable(String))
  end

  sig { returns(T.nilable(String)) }
  def stderr
    compressed = stderr_compressed
    unless compressed.nil?
      @stderr ||= T.let(uncompress(compressed), T.nilable(String))
    end
  end

  sig { params(value: T.nilable(String)).void }
  def stderr=(value)
    self.stderr_compressed = (compress(value) unless value.nil?)
    @stderr = T.let(value, T.nilable(String))
  end

  sig { returns(T.nilable(String)) }
  def vm_log
    compressed = vm_log_compressed
    unless compressed.nil?
      @vm_log ||= T.let(uncompress(compressed), T.nilable(String))
    end
  end

  sig { params(value: T.nilable(String)).void }
  def vm_log=(value)
    self.vm_log_compressed = (compress(value) unless value.nil?)
    @vm_log = T.let(value, T.nilable(String))
  end

  sig { returns(T.nilable(String)) }
  def valgrind
    compressed = valgrind_compressed
    unless compressed.nil?
      @valgrind ||= T.let(uncompress(compressed), T.nilable(String))
    end
  end

  sig { params(value: T.nilable(String)).void }
  def valgrind=(value)
    self.valgrind_compressed = (compress(value) unless value.nil?)
    @valgrind = T.let(value, T.nilable(String))
  end

  sig { returns(T.nilable(String)) }
  def validations
    compressed = validations_compressed
    unless compressed.nil?
      @validations ||= T.let(uncompress(compressed), T.nilable(String))
    end
  end

  sig { params(value: T.nilable(String)).void }
  def validations=(value)
    self.validations_compressed = (compress(value) unless value.nil?)
    @validations = T.let(value, T.nilable(String))
  end

  private
    sig { params(text: String).returns(String) }
    def compress(text)
      Zlib::Deflate.deflate(text)
    end

    sig { params(compressed_text: String).returns(String) }
    def uncompress(compressed_text)
      Zlib::Inflate.inflate(compressed_text).force_encoding('UTF-8')
    end
end
