require 'spec_helper'

describe TmcJunitRunner do
  describe "#get_test_case_methods" do
    describe "on simple java exercises" do
      it "should find all exercise methods" do
        FixtureExercise::SimpleExercise.new('MyExercise')
        methods = TmcJunitRunner.get.get_test_case_methods('MyExercise')
        methods.should include({
          :class_name => 'SimpleTest',
          :method_name => 'testAdd',
          :points => ['simpletest-all', 'both-test-files', 'addsub']
        })
      end
    end

    describe "on maven java exercises" do
      it "should find all exercise methods" do
        FixtureExercise::MavenExercise.new('MyExercise')
        methods = TmcJunitRunner.get.get_test_case_methods('MyExercise')
        methods.should include({
          :class_name => 'SimpleTest',
          :method_name => 'testAdd',
          :points => ['simpletest-all', 'both-test-files', 'addsub']
        })
      end
    end
  end
end
