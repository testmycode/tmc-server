require 'find'

module GitBackend
  extend SystemCommands
  include SystemCommands

  def create_repository
    raise "repository already exists" if repository_exists?

    begin
      copy_model_repository
      link_hooks
      raise "invalid repository" unless valid_repository?
    rescue Exception => e
      delete_repository
      raise e
    end
  end

  def repository_exists?
    FileTest.exists? bare_path
  end

  def delete_repository
    FileUtils.rm_rf bare_path
    FileUtils.rm_rf cache_path
  end

  def clear_cache
    FileUtils.rm_rf cache_path
    FileUtils.mkdir_p [zip_path, clone_path]
  end

  def self.repositories_root
    "#{::Rails.root}/gitrepos"
  end

  def self.model_repository
    "#{::Rails.root}/lib/gitbackend/modelrepo"
  end

  def self.hooks_dir
    "#{::Rails.root}/lib/gitbackend/hooks"
  end

  def self.cache_root
    "#{::Rails.root}/tmp/cache/gitrepos"
  end

  def cache_path
    "#{GitBackend.cache_root}/#{self.name}"
  end

  def bare_path
    "#{GitBackend.repositories_root}/#{self.name}.git"
  end

  def hooks_path
    "#{bare_path}/hooks"
  end

  def zip_path
    "#{cache_path}/zip"
  end

  def clone_path
    "#{cache_path}/clone"
  end

  def exercise_file exercise_name
    "#{zip_path}/#{exercise_name}.zip"
  end

  def valid_repository?
    return false unless FileTest.exists? bare_path
    return false unless valid_hooks?
    return true
  end

  def refresh_working_copy
    system! "git clone -q #{bare_path} #{clone_path}"
  end

  def refresh_exercise_archives
    self.exercises.each do |e|
      Dir.chdir(clone_path) do
        path = "#{clone_path}/#{e.path}"
        system! "git archive --output=#{exercise_file e.name} HEAD #{path}"
      end
    end
  end

  private

  def self.hooks
    Dir.chdir GitBackend.hooks_dir do
      Dir.glob "*"
    end
  end

  def valid_hooks?
    GitBackend.hooks.each do |hook|
      raise "expected #{hook} hook was not found" unless
        FileTest.exists? "#{hooks_path}/#{hook}"
    end
    return true
  end

  def valid_cache?
    return false unless FileTest.exists? zip_path
    return false unless FileTest.exists? clone_path
    return true
  end

  def copy_model_repository
    FileUtils.mkdir_p GitBackend.repositories_root
    FileUtils.cp_r GitBackend.model_repository, bare_path
    system! "chmod g+rwX #{GitBackend.repositories_root}"
    system! "chmod g+rwX -R #{bare_path}"
  end

  def link_hooks
    FileUtils.rm_rf hooks_path
    FileUtils.ln_s GitBackend.hooks_dir, hooks_path
  end

  def self.valid_course_repository? dir
    Exercise.find_exercise_paths(dir).each do |path|
      puts "checking #{path.gsub("#{dir}/", '')}"
      begin
        TestRunner.extract_exercise_list path
      rescue Exception => e
        puts "Invalid: #{e.message}"
        puts "Invalid: #{e.backtrace}"
        return false
      end
    end
    puts "Valid course repository"
    return true
  end
end
