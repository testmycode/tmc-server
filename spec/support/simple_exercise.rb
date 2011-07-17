require 'find'

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
  
  def introduce_compilation_error(text = 'the compiler should fail here')
    replace_method_body_in_file(simple_stuff_path, 'add', "BAD INPUT #{text}")
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
      system!("ant clean > /dev/null 2>&1") unless fixture_clean?
    end
  end
  
private
  def self.fixture_clean?
    Find.find('.') do |path|
      if path.end_with? '.class'
        return false
      end
    end
    true
  end

  def replace_method_body_in_file(path, method, body)
    lines = IO.readlines(path)
    lines = lines.map do |line|
      if line.include? "METHOD BODY #{method}"
        line = body + " // METHOD BODY #{method}\n"
      else
        line
      end
    end
    File.open(path, "wb") {|f| f.write(lines.join) }
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    SimpleExercise.ensure_fixture_clean
  end
end


