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

    def has_tests?
      File.exist?("#{@path}/test") &&
        !(Dir.entries("#{@path}/test") - ['.', '..', '.gitkeep', '.gitignore']).empty?
    end
  end
end
