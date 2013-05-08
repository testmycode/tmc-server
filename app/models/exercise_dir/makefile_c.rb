require 'exercise_dir'

class ExerciseDir
  class MakefileC < ExerciseDir
    #def library_jars
    #  raise "not in C"
    #  #CTODO
    #  #result = []
    #  #(@path + 'lib').find do |file|
    #  #  result << file if file.file? && file.extname == '.jar'
    #  #end
    #  #result
    #end
    
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
