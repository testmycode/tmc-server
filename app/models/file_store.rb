# typed: strict
# frozen_string_literal: true

require 'fileutils'

# Provides an ad-hoc key/value store (db/files).
#
# This class is not used much, although the store directory is
# used directly Course and CourseRefresher.
#
# Note: currently this class provides no concurrency control whatsoever!
module FileStore
  extend T::Sig
  sig { returns(String) }
  def self.root
    "#{::Rails.root}/db/files"
  end

  sig { params(relpath: T.any(String, Pathname)).returns(String) }
  def self.get(relpath)
    File.read(abspath(relpath))
  end

  sig { params(relpath: T.any(String, Pathname)).returns(T.nilable(String)) }
  def self.try_get(relpath)
    get(relpath)
  rescue StandardError
    nil
  end

  sig { params(relpath: T.any(String, Pathname), contents: String).void }
  def self.put(relpath, contents)
    path = abspath(relpath)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.mkdir_p(tmpdir)
    tmpfile = Tempfile.open(File.basename(relpath), tmpdir)
    begin
      tmpfile.write(contents)
      tmpfile.close
      # Note: rename is an all-or-nothing opeartion IF the source and dest are on the same filesystem
      # (which we try to ensure here). Even so, a concurrent operation may breifly see a missing file.
      File.rename(T.must(tmpfile.path), path)
    rescue StandardError
      tmpfile.delete
    end
  end

  sig { params(relpath: T.any(String, Pathname)).returns(Time) }
  def self.mtime(relpath)
    File.mtime(abspath(relpath))
  end

  sig { params(relpath: T.any(String, Pathname)).returns(String) }
  def self.abspath(relpath)
    "#{root}/#{relpath}"
  end

  private
    sig { returns(String) }
    def self.tmpdir
      "#{root}/tmp"
    end
end
