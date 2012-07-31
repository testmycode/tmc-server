require 'exercise_dir'
require 'tempfile'

class ExerciseDir
  class JavaMaven < ExerciseDir
    def library_jars
      if !@jars
        Tempfile.open('classpath') do |tmpfile|
          Dir.chdir @path do
            SystemCommands.sh!('mvn', 'dependency:build-classpath', "-Dmdep.outputFile=#{tmpfile.path}")
          end
          classpath = tmpfile.read.strip
          @jars = classpath.split(":")
        end
      end
      @jars
    end

    def clean!
      Dir.chdir @path do
        SystemCommands.sh!('mvn', 'clean')
      end
    end
  end
end
