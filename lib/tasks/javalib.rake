require 'lib/tmc_javalib.rb'

file TmcJavalib.jar_path do
  puts "Compiling #{TmcJavalib.jar_path} ..."
  TmcJavalib.compile!
end

namespace :javalib do
  desc "Compiles lib/tmc-javalib/dist/tmc-javalib.jar"
  task :compile => TmcJavalib.jar_path
end

# Have rake:spec ensure javalib is compiled
task :spec => TmcJavalib.jar_path

