require 'spec_helper'

describe ApplicationHelper do
  def h(*args) # Hack to make 'h' accessible to the helper being tested (Worked in Rails 3.0, found broken on upgrade to 3.1.1)
    helper.send('h', *args)
  end
 
  describe "#labeled" do
    describe "when given two string parameters" do
      it "should add a label with 1st param as text for the tag given in 2nd param" do
        labeled('Xooxer', '<input type="text" id="foo" name="bar" />').should include('<label for="foo">Xooxer</label><input')
      end
      
      it "and the 2nd param has multiple tags, should add the label for the first tag with an id" do
        labeled('Mooxer', '<div id="moo"><div id="xoo"></div></div>').should include('<label for="moo">Mooxer</label><div')
      end
      
      it "should escape the label text" do
        labeled("Moo & co.", '<div id="moo"></div>').should include('Moo &amp; co.')
      end
      
      it "should raise an error if the 2nd param has no 'id' attribute" do
        expect { labeled("Oopsie", '<div></div>') }.to raise_error
      end
    end
  end
  
  describe "#labeled_field" do
    it "should work like #labeled but wrap the whole thing in a <div class=\"field\">" do
      labeled_field('Xooxer', '<input type="text id="foo" name="foo" />').should ==
        '<div class="field"><label for="foo">Xooxer</label><input type="text id="foo" name="foo" /></div>'
    end
  end
  
  describe "#breadcrumb" do # Not a complete specification
    it "should show the current course" do
      @course = mock_model(Course, :name => 'MyCourse', :new_record? => false)
      breadcrumb.should include('MyCourse')
    end
    
    it "should show the current exercise and its course" do
      @course = mock_model(Course, :name => 'MyCourse', :new_record? => false)
      @exercise = mock_model(Exercise, :name => 'MyExercise', :course => @course, :new_record? => false)
      breadcrumb.should include('MyCourse')
      breadcrumb.should include('MyExercise')
    end
    
    it "should show the current submission, its course and its exercise" do
      @course = mock_model(Course, :name => 'MyCourse', :new_record? => false)
      @exercise = mock_model(Exercise, :name => 'MyExercise', :course => @course, :new_record? => false)
      @submission = mock_model(Submission, :id => 123, :course => @course, :exercise => @exercise, :new_record? => false)
      breadcrumb.should include('MyCourse')
      breadcrumb.should include('MyExercise')
      breadcrumb.should include('Submission #123')
    end
    
    it "should show the current submission, its course and its exercise name even if the exercise was deleted" do
      @course = mock_model(Course, :name => 'MyCourse', :new_record? => false)
      @submission = mock_model(Submission, :id => 123, :course => @course, :exercise_name => 'MyExercise', :new_record? => false)
      breadcrumb.should include('MyCourse')
      breadcrumb.should include('(deleted exercise MyExercise)')
      breadcrumb.should include('Submission #123')
    end
  end
end
