require 'spec_helper'

describe Course do

  let(:source_path) { "#{@test_tmp_dir}/fake_source" }
  let(:source_url) { "file://#{source_path}" }
  let(:user) { Factory.create(:user) }

  describe "gdocs_sheets" do
    it "should list all unique gdocs_sheets of a course" do
      course = Factory.create(:course)
      ex1 = Factory.create(:exercise, :course => course,
                           :gdocs_sheet => "sheet1")
      ex2 = Factory.create(:exercise, :course => course,
                           :gdocs_sheet => "sheet1")
      ex3 = Factory.create(:exercise, :course => course,
                           :gdocs_sheet => "sheet2")
      ex4 = Factory.create(:exercise, :course => course,
                           :gdocs_sheet => nil)
      worksheets = course.gdocs_sheets

      worksheets.size.should == 2
      worksheets.should include("sheet1")
      worksheets.should include("sheet2")
      worksheets.should_not include(nil)
    end
  end

  describe "paths used" do
    it "should be absolute" do
      class_paths = [
        :cache_root
      ]
      for path in class_paths
        Course.send(path).should match(/^\//)
      end

      object_paths = [
        :cache_path,
        :stub_zip_path,
        :solution_zip_path,
        :clone_path
      ]

      for path in object_paths
        Course.new.send(path).should match(/^\//)
      end
    end
  end

  it "should be visible if not hidden and hide_after is nil" do
    c = Factory.create(:course, :hidden => false, :hide_after => nil)
    c.should be_visible_to(user)
  end

  it "should be visible if not hidden and hide_after has not passed" do
    c = Factory.create(:course, :hidden => false, :hide_after => Time.now + 2.minutes)
    c.should be_visible_to(user)
  end

  it "should not be visible if hidden" do
    c = Factory.create(:course, :hidden => true, :hide_after => nil)
    c.should_not be_visible_to(user)
  end

  it "should not be visible if hide_after has passed" do
    c = Factory.create(:course, :hidden => false, :hide_after => Time.now - 2.minutes)
    c.should_not be_visible_to(user)
  end

  it "should always be visible to administrators" do
    admin = Factory.create(:admin)
    c = Factory.create(:course, :hidden => true, :hide_after => Time.now - 2.minutes)
    c.should be_visible_to(admin)
  end

  it "should be visible if user has registered before the hidden_if_registered_after setting" do
    user.created_at = Time.parse('2010-01-02')
    user.save!
    c = Factory.create(:course, :hidden_if_registered_after => Time.parse('2010-01-03'))
    c.should be_visible_to(user)
  end

  it "should not be visible if user has registered after the hidden_if_registered_after setting" do
    user.created_at = Time.parse('2010-01-02')
    user.save!
    c = Factory.create(:course, :hidden_if_registered_after => Time.parse('2010-01-01'))
    c.should_not be_visible_to(user)
  end

  it "should accept Finnish dates and datetimes for hide_after" do
    c = Factory.create(:course)
    c.hide_after = "19.8.2012"
    c.hide_after.day.should == 19
    c.hide_after.month.should == 8
    c.hide_after.year.should == 2012

    c.hide_after = "15.9.2011 19:15"
    c.hide_after.day.should == 15
    c.hide_after.month.should == 9
    c.hide_after.hour.should == 19
    c.hide_after.year.should == 2011
  end

  it "should consider a hide_after date without time to mean the end of that day" do
    c = Factory.create(:course, :hide_after => "18.11.2013")
    c.hide_after.hour.should == 23
    c.hide_after.min.should == 59
  end


  describe "validation" do
    let(:valid_params) do
      {
        :name => 'TestCourse',
        :source_url => 'git@example.com'
      }
    end
    
    it "requires a name" do
      should_be_invalid_params(valid_params.merge(:name => nil))
    end

    it "requires name to be reasonably short" do
      should_be_invalid_params(valid_params.merge(:name => 'a'*41))
    end

    it "requires name to be non-unique" do
      Course.create!(valid_params)
      should_be_invalid_params(valid_params)
    end

    it "forbids spaces in the name" do # this could eventually be lifted as long as everything else is made to tolerate spaces
      should_be_invalid_params(valid_params.merge(:name => 'Test Course'))
    end
    
    it "requires a remote repo url" do
      should_be_invalid_params(valid_params.merge(:source_url => nil))
      should_be_invalid_params(valid_params.merge(:source_url => ''))
    end

    def should_be_invalid_params(params)
      expect { Course.create!(params) }.to raise_error
    end
  end

  describe "destruction" do
    it "deletes its cache directory" do
      c = Course.create!(:name => 'MyCourse', :source_url => source_url)
      FileUtils.mkdir_p(c.cache_path)
      FileUtils.touch("#{c.cache_path}/foo.txt")

      c.destroy
      File.should_not exist(c.cache_path)
    end

    it "deletes dependent exercises" do
      ex = Factory.create(:exercise)
      ex.course.destroy
      assert_destroyed(ex)
    end

    it "deletes dependent submissions" do
      sub = Factory.create(:submission)
      sub.course.destroy
      assert_destroyed(sub)
    end

    it "deletes dependent feedback questions and answers" do
      a = Factory.create(:feedback_answer)
      q = a.feedback_question
      q.course.destroy
      assert_destroyed(a)
      assert_destroyed(q)
    end

    it "deletes available points" do
      pt = Factory.create(:available_point)
      pt.course.destroy
      assert_destroyed(pt)
    end

    it "deletes awarded points" do
      pt = Factory.create(:awarded_point)
      pt.course.destroy
      assert_destroyed(pt)
    end

    it "deletes student events" do
      ev = Factory.create(:student_event)
      ev.course.destroy
      assert_destroyed(ev)
    end

    it "deletes test scanner cache entries" do
      ent = Factory.create(:test_scanner_cache_entry)
      ent.course.destroy
      assert_destroyed(ent)
    end

    def assert_destroyed(obj)
      obj.class.find_by_id(obj.id).should be_nil
    end
  end

end
