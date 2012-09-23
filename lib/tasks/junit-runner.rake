require 'tmc_junit_runner'
require 'fileutils'

runner = TmcJunitRunner.get

file runner.jar_path => FileList["#{runner.path}/**/*.java"] do
  puts "Compiling #{runner.jar_path} ..."
  begin
    runner.compile!
  rescue
    puts "*** Failed to compile tmc-junit-runner ***"
    puts "  Have you done `git submodule update --init`?"
    puts
    raise
  end
  # In case it was already compiled and ant had nothing to do,
  # we'll touch the jar file to make it newer than the deps.
  FileUtils.touch(runner.jar_path) if File.exists?(runner.jar_path)
end

namespace :junit_runner do
  desc "Compiles #{runner.jar_path}"
  task :compile => runner.jar_path
  
  desc "Cleans #{runner.path}"
  task :clean do
    runner.clean_compiled_files!
  end
  
  desc "Forces a recompile of #{runner.jar_path}"
  task :recompile => [:clean, :compile]
end

desc "Compiles #{runner.jar_path}"
task :junit_runner => 'junit_runner:compile'

# Have rake spec ensure tmc-junit-runner is compiled
task :spec => runner.jar_path


