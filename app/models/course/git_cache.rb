require 'course_refresher'

class Course < ActiveRecord::Base
  module GitCache
    def has_remote_repo?
      !remote_repo_url.nil?
    end

    def has_local_repo?
      !has_remote_repo?
    end

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
    end
    
    def delete_cache
      FileUtils.rm_rf cache_path
    end

    def Course.repositories_root
      "#{::Rails.root}/db/local_git_repos"
    end

    def Course.cache_root
      "#{::Rails.root}/tmp/cache/git_repos"
    end

    def cache_path
      "#{Course.cache_root}/#{self.name}-#{self.cache_version}"
    end

    def bare_path
      "#{Course.repositories_root}/#{self.name}.git" if has_local_repo?
    end

    def bare_url
      if has_local_repo?
        "file://#{bare_path}"
      else
        remote_repo_url
      end
    end

    def zip_path
      "#{cache_path}/zip"
    end

    def clone_path
      "#{cache_path}/clone"
    end

    def refresh
      CourseRefresher.new.refresh_course(self)
    end
    
  end
end
