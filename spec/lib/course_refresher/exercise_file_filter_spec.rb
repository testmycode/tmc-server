require 'spec_helper'
require 'fileutils'

describe CourseRefresher::ExerciseFileFilter do

  before :each do
    @filter = CourseRefresher::ExerciseFileFilter.new
  end

  describe "#make_stub" do
    before :each do
      FileUtils.mkdir('original')
      FileUtils.mkdir('stub')
    end
    
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
      @filter.make_stub('original', 'stub')
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
      @filter.make_stub('original', 'stub')
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
      @filter.make_stub('original', 'stub')
      File.should_not exist('stub/Thing.java')
    end
    
    it "should not include hidden tests" do
      make_file('original/HiddenThing.java', '...')
      @filter.make_stub('original', 'stub')
      File.should_not exist('stub/HiddenThing.java')
    end
    
    it "should not include metadata files" do
      make_file('original/metadata.yml', '...')
      @filter.make_stub('original', 'stub')
      File.should_not exist('stub/metadata.yml')
    end
    
    it "should not include git files" do
      make_file('original/.gitignore', '...')
      @filter.make_stub('original', 'stub')
      File.should_not exist('stub/.gitignore')
    end
    
    it "should warn about misplaced stubs"
  end
  
  
  
  
  describe "#make_solution" do
    before :each do
      FileUtils.mkdir('original')
      FileUtils.mkdir('solution')
    end
  
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
      @filter.make_solution('original', 'solution')
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
      @filter.make_solution('original', 'solution')
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
      @filter.make_solution('original', 'solution')
      result = File.read('solution/Thing.java')
      result.should == <<EOF
public class Thing {
    public int foo() {
        return 3;
    }
}
EOF
    end
    
    
    it "should not include any tests" do
      FileUtils.mkdir_p('original/stuff/test')
      make_file('original/stuff/test/Foo.java', '...')
      @filter.make_solution('original', 'solution')
      File.should_not exist('solution/stuff/test/Foo.java')
      File.should_not exist('solution/stuff/test')
    end
    
    it "should not include metadata files" do
      make_file('original/metadata.yml', '...')
      @filter.make_solution('original', 'solution')
      File.should_not exist('solution/metadata.yml')
    end
    
    it "should not include git files" do
      make_file('original/.gitignore', '...')
      @filter.make_solution('original', 'solution')
      File.should_not exist('solution/.gitignore')
    end
  end
  
  def make_file(name, contents)
    File.open(name, 'wb') {|f| f.write(contents) }
  end
end

