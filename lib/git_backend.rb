require 'find'

module GitBackend
  include SystemCommands

  def create_local_repository
    raise "#{bare_path} not empty" if local_repository_exists?

    begin
      FileUtils.mkdir_p(bare_path)
      system!(mk_command ["git", "init", "-q", "--bare", "--shared=group", bare_path])
    rescue Exception => e
      delete_local_repository
      raise e
    end
  end

  def local_repository_exists?
    FileTest.exists? bare_path
  end

  def delete_local_repository
    FileUtils.rm_rf bare_path
    FileUtils.rm_rf cache_path
  end

  def clear_cache
    FileUtils.rm_rf cache_path
    FileUtils.mkdir_p [zip_path, clone_path]
  end

  def self.repositories_root
    "#{::Rails.root}/db/local_git_repos"
  end

  def self.cache_root
    "#{::Rails.root}/tmp/cache/git_repos"
  end

  def cache_path
    "#{GitBackend.cache_root}/#{self.name}-#{self.cache_version}"
  end

  def bare_path
    "#{GitBackend.repositories_root}/#{self.name}.git"
  end

  def bare_url # Overridden if using a remote repo
    "file://#{bare_path}"
  end

  def zip_path
    "#{cache_path}/zip"
  end

  def clone_path
    "#{cache_path}/clone"
  end
end

