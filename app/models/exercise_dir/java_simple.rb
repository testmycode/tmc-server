require 'exercise_dir'

class ExerciseDir
  class JavaSimple < ExerciseDir
    def library_jars
      result = []
      (@path + 'lib').find do |file|
        result << file if file.file? && file.extname == '.jar'
      end
      result
    end

    def clean!
      Dir.chdir @path do
        SystemCommands.sh!('ant', 'clean')
      end
    end
  end
end
