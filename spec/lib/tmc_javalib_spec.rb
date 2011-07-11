require 'spec_helper'

describe TmcJavalib do
  describe "#get_exercise_methods" do
    it "should find all exercise methods", :use_javalib_server => false do
      SimpleExercise.new('MyExercise')
      methods = TmcJavalib.get_exercise_methods('MyExercise/test')
      methods.should include({
        :class_name => 'SimpleTest',
        :method_name => 'testAdd',
        :exercises => ['addsub']
      })
    end
  end
end
