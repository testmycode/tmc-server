require 'fileutils'

# Provides an ad-hoc key/value store (db/files).
#
# This class is not used much, although the store directory is
# used directly Course and CourseRefresher.
#
# Note: currently this class provides no concurrency control whatsoever!
module FileStore
  def self.root
    "#{::Rails.root}/db/files"
  end

  def self.get(relpath)
    File.read(abspath(relpath))
  end

  def self.try_get(relpath)
    begin
      get(relpath)
    rescue
      nil
    end
  end

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
      File.rename(tmpfile.path, path)
    rescue
      tmpfile.delete
    end
  end

  def self.mtime(relpath)
    File.mtime(abspath(relpath))
  end

  def self.abspath(relpath)
    "#{root}/#{relpath}"
  end

private
  def self.tmpdir
    "#{root}/tmp"
  end
end