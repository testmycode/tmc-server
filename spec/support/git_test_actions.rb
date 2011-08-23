module GitTestActions
  include SystemCommands

  def model_repo_path
    "#{::Rails.root}/lib/gitbackend/modelrepo"
  end

  def copy_model_repo(path)
    FileUtils.cp_r(model_repo_path, path)
  end
  
  def clone_empty_course_repo(path)
    clone_repo(model_repo_path, path)
    GitRepo.new(path)
  end

  def clone_course_repo(course_or_course_name)
    if course_or_course_name.is_a?(Course)
      course = course_or_course_name
    else
      course = Course.find_by_name(course_or_course_name)
    end
    
    clone_repo(course.bare_url, course.name + "-wc")
    
    GitRepo.new("#{course.name}-wc")
  end
  
  def clone_repo(from, to)
    system! "git clone -q #{from} #{to}"
  end
end
