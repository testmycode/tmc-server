require 'spec_helper'

describe Version do
  it "splits the version string into components" do
    v("1.20.0.0303").parts.should == [1, 20, 0, 303]
  end

  it "can be compared with other versions" do
    v("0").should == v("0")
    v("1").should == v("1")
    v("0").should < v("1")
    v("1").should > v("0")

    v("0.1").should < v("0.2")
    v("0.2").should > v("0.1")
    v("0.2.9").should > v("0.1.9")
    v("0.2.9").should < v("0.3.9")

    v("0.2.9").should < v("0.2.10")
    v("0.2.10").should > v("0.2.9")

    v("0.2.09").should == v("0.2.09")

    v("1.2.09").should > v("0.2.09")
    v("0.2.09").should < v("1.2.09")

    v("0.2").should < v("0.2.1")
    v("0.2.1").should > v("0.2")
    v("0.2").should == v("0.2.0")
    v("0.2.0").should == v("0.2")
  end

  def v(s)
    Version.new(s)
  end
end