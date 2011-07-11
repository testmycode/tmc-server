require 'lib/system_commands.rb'
require 'lib/tmc_javalib.rb'

file TmcJavalib.jar_path => FileList['.gitmodules'] do
  puts "Compiling #{TmcJavalib.jar_path} ..."
  TmcJavalib.compile!
  # In case it was already compiled and ant had nothing to do,
  # we'll touch the jar file to make it newer than the deps.
  FileUtils.touch(TmcJavalib.jar_path) if File.exists?(TmcJavalib.jar_path)
end

namespace :javalib do
  desc "Compiles #{TmcJavalib.jar_path}"
  task :compile => TmcJavalib.jar_path
  
  desc "Cleans #{TmcJavalib.project_path}"
  task :clean do
    TmcJavalib.clean_compiled_files!
  end
  
  desc "Forces a recompile of #{TmcJavalib.jar_path}"
  task :recompile => [:clean, :compile]
end

# Have rake:spec ensure javalib is compiled
task :spec => TmcJavalib.jar_path

