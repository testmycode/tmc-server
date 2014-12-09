require 'find'
require File.join(File.dirname(File.dirname(__FILE__)), 'fixture_exercise')

class FixtureExercise::MakefileCExercise < FixtureExercise
  def initialize(path = 'MakefileC', options = {})
    options = {
      fixture_name: 'MakefileC'
    }.merge(options)
    super(options[:fixture_name], path, options)
  end

  def solve_all
    solve_only
  end

  def solve_only
    replace_method_body_in_file(lib_c_path, 'return_zero', 'return 0;')
  end

  def introduce_compilation_error
    replace_method_body_in_file(lib_c_path, 'return_zero', "BAD INPUT")
  end

  def lib_c_path
    "#{src_path}/lib.c"
  end

  def src_path
    "#{path}/src"
  end

  # Overriding from fixture_exercise
  def ensure_fixture_clean
    Dir.chdir fixture_path do
      system!("make clean > /dev/null 2>&1")
    end
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

