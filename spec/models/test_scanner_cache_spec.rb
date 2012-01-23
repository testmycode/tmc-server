require 'spec_helper'

describe TestScannerCache do
  def cache
    TestScannerCache
  end
  
  before :each do
    @course = Factory.create(:course)
  end
  
  it "should store missing entries in the cache" do
    cache.get_or_update(@course, 'name', 'hash123') do
      {:a => 'b'}
    end.should == {:a => 'b'}
    
    cache.get_or_update(@course, 'name', 'hash123') do
      raise 'this block should not get called'
    end.should == {:a => 'b'}
  end
  
  it "should propagate exceptions in the constructor block" do
    lambda do
      cache.get_or_update(@course, 'name', 'hash123') do
        raise 'some error'
      end
    end.should raise_error('some error')
  end
  
  it "should differentiate between courses" do
    course1 = Factory.create(:course)
    course2 = Factory.create(:course)
    
    cache.get_or_update(course1, 'name', 'hash123') do
      {:a => 'b'}
    end.should == {:a => 'b'}
    
    cache.get_or_update(course2, 'name', 'hash123') do
      {:c => 'd'}
    end.should == {:c => 'd'}
    
    cache.get_or_update(course1, 'name', 'hash123') do
      raise 'this block should not get called'
    end.should == {:a => 'b'}
    
    cache.get_or_update(course2, 'name', 'hash123') do
      raise 'this block should not get called'
    end.should == {:c => 'd'}
  end
end

