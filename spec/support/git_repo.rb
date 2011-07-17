class GitRepo
  include SystemCommands
  
  attr_reader :path
  
  def initialize(path)
    @path = File.expand_path(path)
    @commit_count = 0
  end
  
  def copy_simple_exercise(name = 'SimpleExercise')
    FileUtils.cp_r(SimpleExercise.fixture_path, "#{@path}/#{name}")
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
