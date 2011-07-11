javalib_jar = 'lib/tmc-javalib/dist/tmc-javalib.jar'

file javalib_jar do
  Dir.chdir 'lib/tmc-javalib' do
    puts "Compiling #{javalib_jar} ..."
    system("ant -q jar")
    raise 'Failed to compile javalib' unless $?.success?
  end
end

namespace :javalib do
  desc "Compiles lib/tmc-javalib/dist/tmc-javalib.jar"
  task :compile => javalib_jar
end

# Have rake:spec ensure javalib is compiled
task :spec => javalib_jar

