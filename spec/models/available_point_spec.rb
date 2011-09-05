require 'spec_helper'

describe AvailablePoint do
  describe "sorting" do
    it "should sort as intended" do
      a = [ Factory.create(:available_point, :name => "1.2"),
            Factory.create(:available_point, :name => "1.20"),
            Factory.create(:available_point, :name => "1.3")].sort!

      a.first.name.should == "1.2"
      a.last.name.should == "1.20"
    end
  end
end

