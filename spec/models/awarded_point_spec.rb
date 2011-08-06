require 'spec_helper'

describe AwardedPoint do

  describe "validation" do
    it "should require a unique point name for each user in each course" do
      course = Factory.create(:course)
      user = Factory.create(:user)
      another_course = Factory.create(:course)
      another_user = Factory.create(:user)
      
      AwardedPoint.create!(:name => '1.1', :course => course, :user => user)
      AwardedPoint.create!(:name => '2.2', :course => course, :user => user)
      AwardedPoint.create!(:name => '1.1', :course => another_course, :user => user)
      AwardedPoint.create!(:name => '1.1', :course => course, :user => another_user)
      
      AwardedPoint.new(:name => '1.1', :course => course, :user => user).should_not be_valid
      expect { AwardedPoint.create!(:name => '1.1', :course => course, :user => user) }.to raise_error
    end
  end

end

