require 'find'

module GitBackend
  extend SystemCommands
  include SystemCommands

  def create_local_repository
    raise "#{bare_path} not empty" if local_repository_exists?

    begin
      copy_model_repository
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

  def self.model_repository
    "#{::Rails.root}/lib/gitbackend/modelrepo"
  end

  def self.cache_root
    "#{::Rails.root}/tmp/cache/git_repos"
  end

  def cache_path
    "#{GitBackend.cache_root}/#{self.name}"
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

  def refresh_working_copy
    system! "git clone -q #{bare_url} #{clone_path}"
  end

  def refresh_exercise_archives
    self.exercises.each do |e|
      Dir.chdir(clone_path) do
        path = "#{clone_path}/#{e.path}"
        zip_file_abs_path = "#{zip_path}/#{e.name}.zip"
        system! "git archive --output=#{zip_file_abs_path} HEAD #{path}"
      end
    end
  end

private

  def copy_model_repository
    FileUtils.mkdir_p GitBackend.repositories_root
    FileUtils.cp_r GitBackend.model_repository, bare_path
    system! "chmod g+rwX #{GitBackend.repositories_root}"
    system! "chmod g+rwX -R #{bare_path}"
  end
end
