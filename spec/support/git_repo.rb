class GitRepo
  include SystemCommands
  
  attr_reader :path
  
  def initialize(path)
    @path = File.expand_path(path)
    @commit_count = 0
  end
  
  def copy_simple_exercise(dir = 'SimpleExercise', metadata = {})
    dest = "#{@path}/#{dir}"
    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp_r(SimpleExercise.fixture_path, dest)
    set_metadata_in(dir, metadata) unless metadata.empty?
  end
  
  def set_metadata_in(dir, metadata_hash)
    dest = "#{@path}/#{dir}/metadata.yml"
    File.open(dest, "wb") { |f| f.write(metadata_hash.to_yaml) }
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
