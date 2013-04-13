require 'exercise_dir'

class ExerciseDir
  class Universal < ExerciseDir

    def clean!
    	#this has been intentionally left blank
    end

    def has_tests?
      File.exist?("#{@path}/.universal/controls/test")
    end
  end
end
