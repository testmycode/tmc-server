require 'spec_helper'

describe TestScannerCache, :type => :model do
  def cache
    TestScannerCache
  end

  before :each do
    @course = FactoryGirl.create(:course)
  end

  it "should store missing entries in the cache" do
    expect(cache.get_or_update(@course, 'name', 'hash123') do
      {:a => 'b'}
    end).to eq({:a => 'b'})

    expect(cache.get_or_update(@course, 'name', 'hash123') do
      raise 'this block should not get called'
    end).to eq({:a => 'b'})
  end

  it "should propagate exceptions in the constructor block" do
    expect do
      cache.get_or_update(@course, 'name', 'hash123') do
        raise 'some error'
      end
    end.to raise_error('some error')
  end

  it "should differentiate between courses" do
    course1 = FactoryGirl.create(:course)
    course2 = FactoryGirl.create(:course)

    expect(cache.get_or_update(course1, 'name', 'hash123') do
      {:a => 'b'}
    end).to eq({:a => 'b'})

    expect(cache.get_or_update(course2, 'name', 'hash123') do
      {:c => 'd'}
    end).to eq({:c => 'd'})

    expect(cache.get_or_update(course1, 'name', 'hash123') do
      raise 'this block should not get called'
    end).to eq({:a => 'b'})

    expect(cache.get_or_update(course2, 'name', 'hash123') do
      raise 'this block should not get called'
    end).to eq({:c => 'd'})
  end
end

