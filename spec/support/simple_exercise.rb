
# Operations on a copy of fixtures/SimpleExercise.
# The fixture has two exercises 'addsub' and 'mul'.
# 'addsub' can be solved partially (so that one test for it succeeds and the other fails).
# 'mul' only has a hidden test.
# By default, both exercises are unsolved. Call solve_all to solve them.
class SimpleExercise
  include SystemCommands
  extend SystemCommands
  
  def initialize(path = 'SimpleExercise')
    raise "Don't use SimpleExercise on the fixture. Use it on a copy." if path == self.class.fixture_path
    @path = path
    FileUtils.cp_r self.class.fixture_path, path if !File.exists? path
  end

  def solve_all
    solve_ex_addsub
  end

  def solve_ex_addsub
    replace_method_body_in_file(simple_stuff_path, 'add', 'return a + b;')
    replace_method_body_in_file(simple_stuff_path, 'sub', 'return a - b;')
  end
  
  def solve_ex_addsub_partially
    replace_method_body_in_file(simple_stuff_path, 'add', 'return a + b;')
  end
  
  def solve_ex_mul
    replace_method_body_in_file(simple_stuff_path, 'mul', 'return a + b;')
  end
  
  def introduce_compilation_error
    replace_method_body_in_file(simple_stuff_path, 'add', 'oops')
  end
  
  def make_zip
    system!("zip -q -0 -r #{@path}.zip #{@path}")
  end
  
  def simple_stuff_path
    "#{@path}/src/SimpleStuff.java"
  end
  
  def simple_test_path
    "#{@path}/test/SimpleTest.java"
  end
  
  def simple_hidden_test_path
    "#{@path}/test/SimpleHiddenTest.java"
  end
  
  def self.fixture_path
    "#{::Rails.root}/spec/fixtures/SimpleExercise"
  end
  
  def self.ensure_fixture_clean
    Dir.chdir fixture_path do
      system!("ant clean > /dev/null 2>&1")
    end
  end
  
private
  def replace_method_body_in_file(path, method, body)
    lines = IO.readlines(path)
    lines.map do |line|
      if line =~ /METHOD BODY #{method}/
        line = body + " // METHOD BODY #{method}"
      else
        line
      end
    end
  end
end

# before :all is run many times for some reason and this is quite slow,
# so we do it when this file is loaded.
SimpleExercise.ensure_fixture_clean


