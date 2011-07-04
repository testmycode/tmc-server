module GitTestActions
  include SystemCommands

  class ClonedRepo
    include SystemCommands
    
    attr_reader :path
    
    def initialize(path)
      @path = path
      @commit_count = 0
    end
    
    def copy_model_exercise(name = 'ModelExercise')
      FileUtils.cp_r("#{::Rails.root}/testdata/exercises/ModelExercise", "#{@path}/#{name}")
    end
    
    def add_commit_push
      add
      commit
      push
    end
    
    def add
      Dir.chdir @path do
        system!("git add -A")
      end
    end
    
    def commit
      Dir.chdir @path do
        @commit_count += 1
        system!("git commit -q -m 'commit #{@commit_count} from test case'")
      end
    end
    
    def push
      Dir.chdir @path do
        system!("git push -q origin master >/dev/null 2>&1")
      end
    end
  end

  def clone_course_repo(course_or_course_name)
    if course_or_course_name.is_a?(Course)
      course = course_or_course_name
    else
      course = Course.find_by_name(course_or_course_name)
    end
    
    FileUtils.pwd.start_with?(@test_tmp_dir).should == true
    system! "git clone -q #{course.bare_path} #{course.name}"
    
    ClonedRepo.new(FileUtils.pwd + "/#{course.name}")
  end
end
