require 'spec_helper'
require 'fileutils'

describe CourseRefresher::ExerciseFileFilter do

  before :each do
    FileUtils.mkdir('original')
    @filter = CourseRefresher::ExerciseFileFilter.new('original')
  end

  describe "#make_stub" do
    before :each do
      FileUtils.mkdir('stub')
    end


    describe "with java files" do
      it "should remove solution blocks" do
        make_file 'original/Thing.java', <<EOF
public class Thing {
    // BEGIN SOLUTION
    public int foo() {
        return 3;
    }
    // END SOLUTION

    public void bar() {
        // BEGIN SOLUTION
        System.out.println("hello");
        // END SOLUTION
    }
}
EOF
        @filter.make_stub('stub')
        result = File.read('stub/Thing.java')
        result.should == <<EOF
public class Thing {

    public void bar() {
    }
}
EOF
      end


      it "should uncomment stubs" do
        make_file 'original/Thing.java', <<EOF
public class Thing {
    public int foo() {
        // BEGIN SOLUTION
        return 3;
        // END SOLUTION
        // STUB: return 0;
    }
}
EOF
        @filter.make_stub('stub')
        result = File.read('stub/Thing.java')
        result.should == <<EOF
public class Thing {
    public int foo() {
        return 0;
    }
}
EOF
      end


      it "should not include solution files" do
        make_file 'original/Thing.java', <<EOF
// SOLUTION FILE
public class Thing {
    public int foo() {
        return 3;
    }
}
EOF
        @filter.make_stub('stub')
        File.should_not exist('stub/Thing.java')
      end

    end


    describe "with XML files" do
      it "should remove solution blocks" do
        make_file 'original/Thing.xml', <<EOF
<trol>
  <lol/>
  <!-- BEGIN SOLUTION -->
  <loo/>
  <!-- END SOLUTION -->
</trol>
EOF
        @filter.make_stub('stub')
        result = File.read('stub/Thing.xml')
        result.should == <<EOF
<trol>
  <lol/>
</trol>
EOF
      end


      it "should uncomment stubs" do
        make_file 'original/Thing.xml', <<EOF
<trol>
  <lol/>
  <!-- BEGIN SOLUTION -->
  <loo/>
  <!-- END SOLUTION -->
  <!-- STUB:
  <foo>
  </foo>
  -->
</trol>
EOF
        @filter.make_stub('stub')
        result = File.read('stub/Thing.xml')
        result.should == <<EOF
<trol>
  <lol/>
  <foo>
  </foo>
</trol>
EOF
      end


      it "should not include solution files" do
        make_file 'original/Thing.xml', <<EOF
<!-- SOLUTION FILE -->
<trol>
  <lol/>
</trol>
EOF
        @filter.make_stub('stub')
        File.should_not exist('stub/Thing.xml')
      end
    end


    describe "with properties files" do
      it "should remove solution blocks" do
        make_file 'original/Thing.properties', <<EOF
trol = foo
# BEGIN SOLUTION
lol = bar
# END SOLUTION
loo = xoo
EOF
        @filter.make_stub('stub')
        result = File.read('stub/Thing.properties')
        result.should == <<EOF
trol = foo
loo = xoo
EOF
      end


      it "should uncomment stubs" do
        make_file 'original/Thing.properties', <<EOF
trol = foo
# BEGIN SOLUTION
lol = bar
# END SOLUTION
# STUB: loo = xoo
EOF
        @filter.make_stub('stub')
        result = File.read('stub/Thing.properties')
        result.should == <<EOF
trol = foo
loo = xoo
EOF
      end


      it "should not include solution files" do
        make_file 'original/Thing.properties', <<EOF
# SOLUTION FILE
trol = foo
lol = bar
loo = xoo
EOF
        @filter.make_stub('stub')
        File.should_not exist('stub/Thing.properties')
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
    
    it "should warn about misplaced stubs"
  end
  



  
  
  describe "#make_solution" do
    before :each do
      FileUtils.mkdir('solution')
    end


    describe "with java files" do
      it "should remove stubs" do
        make_file 'original/Thing.java', <<EOF
public class Thing {
    public int foo() {
        // BEGIN SOLUTION
        return 3;
        // END SOLUTION
        // STUB: return 0;
    }
}
EOF
        @filter.make_solution('solution')
        result = File.read('solution/Thing.java')
        result.should == <<EOF
public class Thing {
    public int foo() {
        return 3;
    }
}
EOF
      end


      it "should remove solution block comments" do
        make_file 'original/Thing.java', <<EOF
public class Thing {
    // BEGIN SOLUTION
    public int foo() {
        return 3;
    }
    // END SOLUTION

    public void bar() {
        // BEGIN SOLUTION
        System.out.println("hello");
        // END SOLUTION
    }
}
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


      it "should remove solution file comments" do
        make_file 'original/Thing.java', <<EOF
// SOLUTION FILE
public class Thing {
    public int foo() {
        return 3;
    }
}
EOF
        @filter.make_solution('solution')
        result = File.read('solution/Thing.java')
        result.should == <<EOF
public class Thing {
    public int foo() {
        return 3;
    }
}
EOF
      end

    end


    describe "with XML files" do
      it "should remove stubs" do
        make_file 'original/Thing.xml', <<EOF
<trol>
  <lol/>
  <!-- STUB:
  <foo>
  </foo>
  -->
</trol>
EOF
        @filter.make_solution('solution')
        result = File.read('solution/Thing.xml')
        result.should == <<EOF
<trol>
  <lol/>
</trol>
EOF
      end


      it "should remove solution block comments" do
        make_file 'original/Thing.xml', <<EOF
<trol>
  <lol/>
  <!-- BEGIN SOLUTION -->
  <loo/>
  <!-- END SOLUTION -->
</trol>
EOF
        @filter.make_solution('solution')
        result = File.read('solution/Thing.xml')
        result.should == <<EOF
<trol>
  <lol/>
  <loo/>
</trol>
EOF
      end


      it "should remove solution file comments" do
        make_file 'original/Thing.xml', <<EOF
<!-- SOLUTION FILE -->
<trol>
  <lol/>
</trol>
EOF
        @filter.make_solution('solution')
        result = File.read('solution/Thing.xml')
        result.should == <<EOF
<trol>
  <lol/>
</trol>
EOF
      end
    end


    describe "with properties files" do
      it "should remove stubs" do
        make_file 'original/Thing.properties', <<EOF
trol = foo
# STUB: lol = bar
loo = xoo
EOF
        @filter.make_solution('solution')
        result = File.read('solution/Thing.properties')
        result.should == <<EOF
trol = foo
loo = xoo
EOF
      end


      it "should remove solution block comments" do
        make_file 'original/Thing.properties', <<EOF
trol = foo
# BEGIN SOLUTION
lol = bar
# END SOLUTION
loo = xoo
EOF
        @filter.make_solution('solution')
        result = File.read('solution/Thing.properties')
        result.should == <<EOF
trol = foo
lol = bar
loo = xoo
EOF
      end


      it "should remove solution file comments" do
        make_file 'original/Thing.properties', <<EOF
# SOLUTION FILE
trol = foo
lol = bar
loo = xoo
EOF
        @filter.make_solution('solution')
        result = File.read('solution/Thing.properties')
        result.should == <<EOF
trol = foo
lol = bar
loo = xoo
EOF
      end
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

