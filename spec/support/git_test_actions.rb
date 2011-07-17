module GitTestActions
  include SystemCommands

  def copy_model_repo(path)
    FileUtils.cp_r "#{::Rails.root}/lib/gitbackend/modelrepo", path
  end

  def clone_course_repo(course_or_course_name)
    if course_or_course_name.is_a?(Course)
      course = course_or_course_name
    else
      course = Course.find_by_name(course_or_course_name)
    end
    
    FileUtils.pwd.start_with?(@test_tmp_dir).should == true
    system! "git clone -q #{course.bare_url} #{course.name}"
    
    GitRepo.new("#{course.name}")
  end
end
