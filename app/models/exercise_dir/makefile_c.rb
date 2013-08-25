require 'exercise_dir'

class ExerciseDir
  class MakefileC < ExerciseDir
    def clean!
      Dir.chdir @path do
        SystemCommands.sh!('make', 'clean')
      end
    end

    def has_tests?
      File.exist?("#{@path}/test") &&
        !(Dir.entries("#{@path}/test") - ['.', '..', '.gitkeep', '.gitignore']).empty?
    end
  end
end
