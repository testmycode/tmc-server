require 'fileutils'

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