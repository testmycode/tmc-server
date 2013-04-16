require 'find'
require File.join(File.dirname(File.dirname(__FILE__)), 'fixture_exercise')

# Operations on a copy of fixtures/SimpleExercise.
# The fixture has two exercises 'addsub' and 'mul'.
# 'addsub' can be solved partially (so that one test for it succeeds and the other fails).
# 'mul' only has a hidden test.
# By default, both exercises are unsolved. Call solve_all to solve them.
class FixtureExercise::UniversalRubyExercise < FixtureExercise
  def initialize(path = 'UniversalRuby', options = {})
    options = {
      :fixture_name => 'UniversalRuby'
    }.merge(options)
    super(options[:fixture_name], path)
  end

  def solve_all
    solve_only
  end

  def solve_only
    replace_method_body_in_file(simple_stuff_path, 'return_zero', '0;')
  end

  def introduce_compilation_error(text = 'the compiler should fail here')
    true
  end

  def simple_stuff_path
    "#{java_src_path}/library.rb"
  end

  def java_src_path
    "#{@path}/lib"
  end

  def java_test_path
    "#{@path}/.universal/controls/test"
  end

  #Overwriting from fixture_exercise
  def ensure_fixture_clean
    true
  end

  def fixture_contains_class_files?
    false
  end
private

  def copy_libs
  	#empty
  end

  def copy_gitignore
    FileUtils.ln("#{common_files_path}/.gitignore", "#{path}/.gitignore")
  end

  def copy_src
    FileUtils.cp_r("#{fixture_path}/.", "#{path}/")
  end

  def copy_tests
  	#empty
  end

  def replace_method_body_in_file(path, method, body)
    lines = IO.readlines(path)
    lines = lines.map do |line|
      if line.include? "METHOD BODY #{method}"
        body + " # METHOD BODY #{method}\n"
      else
        line
      end
    end
    File.open(path, "wb") {|f| f.write(lines.join) }
  end
end

