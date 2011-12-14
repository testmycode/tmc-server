require 'tmc_junit_runner'
require 'fileutils'

file TmcJunitRunner.jar_path => FileList["#{TmcJunitRunner.project_path}/**/*.java"] do
  puts "Compiling #{TmcJunitRunner.jar_path} ..."
  begin
    TmcJunitRunner.compile!
  rescue
    puts "*** Failed to compile tmc-junit-runner ***"
    puts "  Have you done `git submodule update --init`?"
    puts
    raise
  end
  # In case it was already compiled and ant had nothing to do,
  # we'll touch the jar file to make it newer than the deps.
  FileUtils.touch(TmcJunitRunner.jar_path) if File.exists?(TmcJunitRunner.jar_path)
end

namespace :junit_runner do
  desc "Compiles #{TmcJunitRunner.jar_path}"
  task :compile => TmcJunitRunner.jar_path
  
  desc "Cleans #{TmcJunitRunner.project_path}"
  task :clean do
    TmcJunitRunner.clean_compiled_files!
  end
  
  desc "Forces a recompile of #{TmcJunitRunner.jar_path}"
  task :recompile => [:clean, :compile]
end

desc "Compiles #{TmcJunitRunner.jar_path}"
task :junit_runner => 'junit_runner:compile'

# Have rake spec ensure tmc-junit-runner is compiled
task :spec => TmcJunitRunner.jar_path


