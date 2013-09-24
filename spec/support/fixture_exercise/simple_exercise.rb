require 'find'
require File.join(File.dirname(File.dirname(__FILE__)), 'fixture_exercise')

# Operations on a copy of fixtures/SimpleExercise.
# The fixture has two exercises 'addsub' and 'mul'.
# 'addsub' can be solved partially (so that one test for it succeeds and the other fails).
# 'mul' only has a hidden test.
# By default, both exercises are unsolved. Call solve_all to solve them.
class FixtureExercise::SimpleExercise < FixtureExercise
  def initialize(path = 'SimpleExercise', options = {})
    options = {
      :fixture_name => 'SimpleExercise'
      }.merge(options)
      super(options[:fixture_name], path)
    end

    def solve_all
      solve_addsub
      solve_mul
    end

    def solve_addsub
      solve_add
      solve_sub
    end

    def solve_add
      replace_method_body_in_file(simple_stuff_path, 'add', 'return a + b;')
    end

    def solve_sub
      replace_method_body_in_file(simple_stuff_path, 'sub', 'return a - b;')
    end

    def solve_mul
      replace_method_body_in_file(simple_stuff_path, 'mul', 'return a * b;')
    end

    def write_empty_method_body(code)
      replace_method_body_in_file(simple_stuff_path, 'emptyMethod', code)
    end

    def introduce_compilation_error(text = 'the compiler should fail here')
      replace_method_body_in_file(simple_stuff_path, 'add', "BAD INPUT #{text}")
    end

    def simple_stuff_path
      "#{java_src_path}/SimpleStuff.java"
    end

    def simple_test_path
      "#{java_test_path}/SimpleTest.java"
    end

    def simple_hidden_test_path
      "#{java_test_path}/SimpleHiddenTest.java"
    end

    def java_src_path
      "#{@path}/src"
    end

    def java_test_path
      "#{@path}/test"
    end

    private

    def replace_method_body_in_file(path, method, body)
      lines = IO.readlines(path)
      lines = lines.map do |line|
        if line.include? "METHOD BODY #{method}"
          body + " // METHOD BODY #{method}\n"
        else
          line
        end
      File.open(path, "wb") {|f| f.write(lines.join) }
    end
  end
end