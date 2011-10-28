module GitTestActions
  include SystemCommands

  def create_bare_repo(path, options = {})
    options = {:initial_commit => true}.merge(options)
    abs_path = File.expand_path(path)
    system!("git init -q --bare #{path}")
    
    if options[:initial_commit] # To avoid pesky warning about cloning empty repos
      Dir.mktmpdir do |tmpdir|
        system!("git init -q #{tmpdir}")
        Dir.chdir(tmpdir) do
          system!("echo Hello > README")
          system!("git add README")
          system!("git commit -qm \"Added dummy README\"")
          system!("git remote add origin #{abs_path}")
          system!("git push -q origin master >/dev/null 2>&1")
        end
      end
    end
    nil
  end

  def clone_course_repo(course_or_course_name)
    if course_or_course_name.is_a?(Course)
      course = course_or_course_name
    else
      course = Course.find_by_name(course_or_course_name)
    end
    
    raise 'Course not using git but ' + course.source_backend if course.source_backend != 'git'
    clone_repo(course.source_url, course.name + "-wc")
    
    GitRepo.new("#{course.name}-wc")
  end
  
  def clone_repo(from, to)
    # silencing warning about cloning empty repo
    system!("git clone -q #{from} #{to} >/dev/null 2>&1")
  end
end
