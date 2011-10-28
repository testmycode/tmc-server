require 'course_refresher'

class Course < ActiveRecord::Base
  module GitCache
    def delete_cache
      FileUtils.rm_rf cache_path
    end

    def Course.cache_root
      "#{::Rails.root}/tmp/cache/git_repos"
    end

    def cache_path
      "#{Course.cache_root}/#{self.name}-#{self.cache_version}"
    end

    # :deprecated:
    def bare_url
      remote_repo_url # to be renamed as well
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
