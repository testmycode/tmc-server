require 'spec_helper'
require 'fileutils'

# TODO: clean this up. Perhaps put cases into their own files.
describe CourseRefresher::ExerciseFileFilter do

  before :each do
    FileUtils.mkdir('original')
    @filter = CourseRefresher::ExerciseFileFilter.new('original')
  end

  def self.make_test_cases(test_case_subdir, method)
    target_dir = test_case_subdir
    FileUtils.mkdir_p(target_dir)

    test_case_dir = File.dirname(__FILE__) + "/test_cases/#{test_case_subdir}"
    input_files = (Dir.entries(test_case_dir) - ['.', '..']).select {|f| f.include?('.in.') }

    input_files.each do |input_file|
      output_file = input_file.sub('.in.', '.out.')
      bare_file = input_file.sub('.in.', '.')

      if File.exist?("#{test_case_dir}/#{output_file}")
        specify "#{input_file} => #{output_file}" do
          FileUtils.cp("#{test_case_dir}/#{input_file}", "original/#{bare_file}")
          @filter.send(method, target_dir)
          result = File.read("#{target_dir}/#{bare_file}")
          result.should == File.read("#{test_case_dir}/#{output_file}")
        end
      else
        specify "#{input_file} should be deleted" do
          FileUtils.cp("#{test_case_dir}/#{input_file}", "original/#{bare_file}")
          @filter.send(method, target_dir)
          File.should_not exist("#{target_dir}/#{bare_file}")
        end
      end
    end
  end

  describe "#make_stub" do
    before :each do
      FileUtils.mkdir('stub')
    end

    make_test_cases('stub', :make_stub)

    #TODO: test other stuff and solutions too
    describe "with CSS files" do
      it "should not include solution files" do
        make_file 'original/thing.css', <<EOF
/* SOLUTION FILE */
trol { color: red; }
EOF

        @filter.make_stub('stub')
        File.should_not exist('stub/thing.css')
      end
    end


    it "should not include directories under src/ containing only solution files" do
      FileUtils.mkdir_p 'original/src/foo/bar'
      make_file 'original/src/foo/bar/Thing.java', '//SOLUTION FILE'
      make_file 'original/src/foo/Remaining.java', '//This file should remain'
      @filter.make_stub('stub')

      File.should exist('stub/src')
      File.should exist('stub/src/foo')
      File.should exist('stub/src/foo/Remaining.java')
      File.should_not exist('stub/src/foo/bar/Thing.java')
      File.should_not exist('stub/src/foo/bar')
    end

    it "should still include src/ even if it contains only solution files" do
      FileUtils.mkdir_p 'original/src'
      make_file 'original/src/Thing.java', '//SOLUTION FILE'
      @filter.make_stub('stub')

      File.should_not exist('stub/src/Thing.java')
      File.should exist('stub/src')
    end
    
    it "should convert end-of-lines to unix style" do
      make_file 'original/Thing.java', <<EOF
public class Thing {\r
    // BEGIN SOLUTION\r
    public int foo() {\r
        return 3;\r
    }\r
    // END SOLUTION\r
    \r
    public void bar() {\r
        // BEGIN SOLUTION\r
        System.out.println("hello");\r
        // END SOLUTION\r
        // STUB: // code here\r
    }\r
}\r
EOF
      @filter.make_stub('stub')
      result = File.read('stub/Thing.java')
      result.should == <<EOF
public class Thing {
    
    public void bar() {
        // code here
    }
}
EOF
    end

    it "should remove html comments" do
      make_file 'original/Thing.java', <<EOF
/*
 * PREPEND HTML
 * <p>foo</p>
 */
public class Thing {
}
EOF
      @filter.make_stub('stub')
      result = File.read('stub/Thing.java')
      result.should == <<EOF
public class Thing {
}
EOF
    end
    
    it "should not include hidden tests" do
      make_file('original/HiddenThing.java', '...')
      @filter.make_stub('stub')
      File.should_not exist('stub/HiddenThing.java')
    end
    
    it "should not include metadata files" do
      make_file('original/metadata.yml', '...')
      @filter.make_stub('stub')
      File.should_not exist('stub/metadata.yml')
    end
    
    it "should not include git files" do
      make_file('original/.gitignore', '...')
      @filter.make_stub('stub')
      File.should_not exist('stub/.gitignore')
    end

    it "should include .tmcproject.yml" do
      make_file('original/.tmcproject.yml', '---')
      @filter.make_stub('stub')
      File.should exist('stub/.tmcproject.yml')
    end

    it "should not include .tmcrc" do
      make_file('original/.tmcrc', '---')
      @filter.make_stub('stub')
      File.should_not exist('stub/.tmcrc')
    end
  end

  
  
  describe "#make_solution" do
    before :each do
      FileUtils.mkdir('solution')
    end

    make_test_cases('solution', :make_solution)


    it "should convert end-of-lines to unix style" do
      make_file 'original/Thing.java', <<EOF
public class Thing {\r
    // BEGIN SOLUTION\r
    public int foo() {\r
        return 3;\r
    }\r
    // END SOLUTION\r
    \r
    public void bar() {\r
        // BEGIN SOLUTION\r
        System.out.println("hello");\r
        // END SOLUTION\r
        // STUB: // code here
    }\r
}\r
EOF
      @filter.make_solution('solution')
      result = File.read('solution/Thing.java')
      result.should == <<EOF
public class Thing {
    public int foo() {
        return 3;
    }
    
    public void bar() {
        System.out.println("hello");
    }
}
EOF
    end 


    it "should remove html comments and make files out of them" do
      make_file 'original/Thing.java', <<EOF
/*
 * PREPEND HTML <strong>hi</strong>
 * <p>foo</p>
 * <p>bar</p>
 */
public class Thing {
}
EOF
      @filter.make_solution('solution')
      result = File.read('solution/Thing.java')
      result.should == <<EOF
public class Thing {
}
EOF

      html_file = File.read('solution/Thing.java.html')
      html_file.should == <<EOF
<strong>hi</strong>
<p>foo</p>
<p>bar</p>
EOF
    end
    
    it "should not include any tests" do
      FileUtils.mkdir_p('original/test')
      make_file('original/test/Foo.java', '...')
      @filter.make_solution('solution')
      File.should_not exist('solution/test/Foo.java')
    end
    
    it "should not include metadata files" do
      make_file('original/metadata.yml', '...')
      @filter.make_solution('solution')
      File.should_not exist('solution/metadata.yml')
    end
    
    it "should not include git files" do
      make_file('original/.gitignore', '...')
      @filter.make_solution('solution')
      File.should_not exist('solution/.gitignore')
    end

    it "should not include .tmcproject.yml" do
      make_file('original/.tmcproject.yml', '---')
      @filter.make_solution('solution')
      File.should_not exist('solution/.tmcproject.yml')
    end

    it "should not include .tmcrc" do
      make_file('original/.tmcrc', '---')
      @filter.make_stub('solution')
      File.should_not exist('solution/.tmcrc')
    end

    it "should include extra student files specified in .tmcproject.yml" do
      make_file('original/.tmcproject.yml', "extra_student_files:\n  - test/Foo.java")
      FileUtils.mkdir('original/test')
      make_file('original/test/Foo.java', "// This should be in the solution")
      make_file('original/test/Bar.java', "// This should not be in the solution")

      @filter = CourseRefresher::ExerciseFileFilter.new('original')
      @filter.make_solution('solution')

      File.should exist('solution/test')
      File.should exist('solution/test/Foo.java')
      File.should_not exist('solution/test/Bar.java')
    end
  end
  
  def make_file(name, contents)
    File.open(name, 'wb') {|f| f.write(contents) }
  end
end

