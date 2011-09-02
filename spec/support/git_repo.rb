class GitRepo
  include SystemCommands
  
  attr_reader :path
  
  def initialize(path)
    @path = File.expand_path(path)
    @commit_count = 0
  end
  
  def copy_simple_exercise(dest_name = nil, metadata = {})
    copy_fixture_exercise('SimpleExercise', dest_name, metadata)
  end
  
  def copy_fixture_exercise(src_name, dest_name = nil, metadata = {})
    dest_name ||= src_name
    
    dest = "#{@path}/#{dest_name}"

    ex = FixtureExercise.new(src_name, dest)
    ex.write_metadata(metadata) unless metadata.empty?
    ex
  end
  
  def set_metadata_in(dir, metadata_hash)
    write_file("#{dir}/metadata.yml", metadata_hash.to_yaml)
  end
  
  def write_file(name, content)
    raise 'Expected relative path' if name.start_with?('/')
    File.open("#{@path}/#{name}", "wb") {|f| f.write(content) }
  end
  
  def debug_list_files
    system('find', @path)
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
