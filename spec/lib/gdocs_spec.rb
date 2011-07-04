#tested funtions through main method with wrong, empty and negative attributes

require 'gdocs'

test = GDocs.new

describe GDocs do

  before(:each) do
    #these values exists in the real document
    @course_name = 'testGDocs'
    @student_id = 13816074
    @week = 1
    @exercise = '3.1'
    @document = test.get_document_from_google(@course_name)
  end

 describe "add a point to the student who doesn't exist" do
  it "add_points_to_student '13816070' should raise error" do
    @student_id = 13816070
    expect {
      test.add_points_to_student(@course_name, @student_id, @week, @exercise)
    }.to raise_error
  end
  it "add_points_to_student 'empty' should raise error" do
    @student_id = / /
    expect {
      test.add_points_to_student(@course_name, @student_id, @week, @exercise)
    }.to raise_error
  end
  it "add_points_to_student 'negative' should raise error" do
    @student_id = -13816074
    expect {
      test.add_points_to_student(@course_name, @student_id, @week, @exercise)
    }.to raise_error
  end
  it "add_points_to_student '-1' should raise error" do
    @student_id = -1
    expect {
      test.add_points_to_student(@course_name, @student_id, @week, @exercise)
    }.to raise_error
  end
   it "add_points_to_student 'nil' should fail" do 
    @student_id = nil
    test.add_points_to_student(@course_name, @student_id, @week, @exercise).should be_false
  end
   it "add_points_to_student '1' should raise error" do 
    @student_id = 1
    expect {
      test.add_points_to_student(@course_name, @student_id, @week, @exercise)
    }.to raise_error
  end
 end
 
 describe "add a point to the student with a wrong course" do 
  it "add_points_to_student for course 'Alias' should raise error" do
    @course_name = 'Alias'
    expect {
      test.add_points_to_student(@course_name, @student_id, @week, @exercise)
    }.to raise_error
  end
  it "add_points_to_student for course 'test GDocs' should raise error" do
    @course_name = 'test GDocs'
    expect {
      test.add_points_to_student(@course_name, @student_id, @week, @exercise)
    }.to raise_error
  end
  it "add_points_to_student for course 'negative' should raise error" do
    @course_name = '-testGDocs'
    expect {
      test.add_points_to_student(@course_name, @student_id, @week, @exercise)
    }.to raise_error
  end
 end
 
 describe "add a point to the student with wrong week" do 
  it "add_points_to_student with wrong week number should raise error" do
    @week = 4
    test.add_points_to_student(@course_name, @student_id, @week, @xercise).should raise_error
  end
  it "add_points_to_student with 'empty week' should raise error" do
    @week = / /
    test.add_points_to_student(@course_name, @student_id, @week, @xercise).should raise_error
  end
   it "add_points_to_student with negative week should raise error" do
    @week = -1
    test.add_points_to_student(@course_name, @student_id, @week, @xercise).should raise_error
  end
  it "add_points_to_student with 'nil' week should fail" do
    @week = nil
    test.add_points_to_student(@course_name, @student_id, @week, @xercise).should be_false
  end
 end
 
 describe "add a point to the student with wrong exersice" do
  it "add_points_to_student with wrong exersice number should raise error" do
    @exersice = 4
    test.add_points_to_student(@course_name, @student_id, @week, @xercise).should raise_error
  end
  it "add_points_to_student with empty exersice number should raise error" do
    @exersice = / /
    test.add_points_to_student(@course_name, @student_id, @week, @xercise).should raise_error
  end
  it "add_points_to_student with negative exersice number should raise error" do
    @exersice = '-3.1'
    test.add_points_to_student(@course_name, @student_id, @week, @xercise).should raise_error
  end
 end 
end
