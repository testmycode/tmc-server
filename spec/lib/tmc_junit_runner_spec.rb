require 'spec_helper'

describe TmcJunitRunner do
  describe "#get_test_case_methods" do
    it "should find all exercise methods" do
      SimpleExercise.new('MyExercise')
      methods = TmcJunitRunner.get_test_case_methods('MyExercise')
      methods.should include({
        :class_name => 'SimpleTest',
        :method_name => 'testAdd',
        :points => ['simpletest-all', 'both-test-files', 'addsub']
      })
    end
  end
end
