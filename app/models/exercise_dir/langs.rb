require 'exercise_dir'
require 'tempfile'

class ExerciseDir
  class Langs < ExerciseDir
    def library_jars
      raise "not in langs"
      unless @jars
        Tempfile.open('classpath') do |tmpfile|
          Dir.chdir @path do
            SystemCommands.sh!('mvn', 'dependency:build-classpath', "-Dmdep.outputFile=#{tmpfile.path}")
          end
          classpath = tmpfile.read.strip
          @jars = classpath.split(':')
        end
      end
      @jars
    end

    def clean!
      Dir.chdir @path do
        raise "do in langs"
      end
    end

    def has_tests?
      true # why not to default like this
    end

    def safe_for_experimental_sandbox
      true
    end
  end
end
