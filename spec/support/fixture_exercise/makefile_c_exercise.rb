require 'find'
require File.join(File.dirname(File.dirname(__FILE__)), 'fixture_exercise')

# Operations on a copy of fixtures/SimpleExercise.
# The fixture has two exercises 'addsub' and 'mul'.
# 'addsub' can be solved partially (so that one test for it succeeds and the other fails).
# 'mul' only has a hidden test.
# By default, both exercises are unsolved. Call solve_all to solve them.
class FixtureExercise::MakefileCExercise < FixtureExercise
  def initialize(path = 'MakefileC', options = {})
    options = {
      :fixture_name => 'MakefileC'
    }.merge(options)
    super(options[:fixture_name], path)
  end

  def solve_all
    solve_only
  end

  #def solve_addsub
  #  solve_add
  #  solve_sub
  #end METHOD BODY 

  def solve_only
    replace_method_body_in_file(simple_stuff_path, 'return_zero', 'return 0;')
  end
  
  #def write_empty_method_body(code)
  #  replace_method_body_in_file(simple_stuff_path, 'emptyMethod', code)
  #end
  
  def introduce_compilation_error
    replace_method_body_in_file(simple_stuff_path, 'return_zero', "BAD INPUT")
  end
  
  def simple_stuff_path
    "#{java_src_path}/lib.c"
  end
  
  #def simple_test_path
  #  "#{java_test_path}/SimpleTest.java"
  #end
  
  #def simple_hidden_test_path
  #  "#{java_test_path}/SimpleHiddenTest.java"
  #end

  def java_src_path
    "#{@path}/src"
  end

  def java_test_path
    "#{@path}/test"
  end
  
  #Overwriting from fixture_exercise
  def ensure_fixture_clean
    Dir.chdir fixture_path do
      system!("make clean > /dev/null 2>&1")
    end unless fixture_clean?
  end

  def fixture_contains_class_files?
    true # for now we want allways to clean (make clean)
  end
private

  alias_method :old_copy_from_fixture, :copy_from_fixture

  def copy_from_fixture
    old_copy_from_fixture
    copy_makefile
  end

  def copy_makefile
    FileUtils.cp_r("#{fixture_path}/Makefile", "#{path}/Makefile")
  end


  def replace_method_body_in_file(path, method, body)
    lines = IO.readlines(path)
    lines = lines.map do |line|
      if line.include? "METHOD BODY #{method}"
        body + " // METHOD BODY #{method}\n"
      else
        line
      end
    end
    File.open(path, "wb") {|f| f.write(lines.join) }
  end
end

