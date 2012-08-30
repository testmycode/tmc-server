require 'spec_helper'

describe DateAndTimeUtils do
  describe "#to_time" do
    it "should parse time strings to time" do
      t = DateAndTimeUtils.to_time("15.07.2011 13:45")
      t.should be_a(Time)
      t.day.should == 15
      t.hour.should == 13
    end
    
    it "should convert dates to local midnight time" do
      t = DateAndTimeUtils.to_time("15.07.2011")
      t.should be_a(Time)
      t.day.should == 15
      t.hour.should == 00
      t.min.should == 00
    end
    
    it "should can convert dates to local end of day time" do
      t = DateAndTimeUtils.to_time("15.07.2011", :prefer_end_of_day => true)
      t.should be_a(Time)
      t.day.should == 15
      t.hour.should == 23
      t.min.should == 59
      
      t = DateAndTimeUtils.to_time("15.07.2011 13:14", :prefer_end_of_day => true)
      t.hour.should == 13
      t.min.should == 14
    end
    
    it "should convert blanks to nil" do
      DateAndTimeUtils.to_time(nil).should be_nil
      DateAndTimeUtils.to_time("").should be_nil
      DateAndTimeUtils.to_time("   ").should be_nil
    end
  end

  describe "#parse_date_or_time" do
    it "should accept (local time) SQL-like yyyy-mm-dd date strings" do
      d = DateAndTimeUtils.parse_date_or_time('2011-07-13')
      d.should be_a(Date)
      d.day.should == 13
      d.month.should == 07
      d.year.should == 2011
    end
    
    it "should accept (local time) SQL-like yyyy-mm-dd hh:ii datetime strings" do
      t = DateAndTimeUtils.parse_date_or_time('2011-07-13 13:45')
      t.should be_a(Time)
      t.day.should == 13
      t.month.should == 07
      t.year.should == 2011
      t.hour.should == 13
      t.min.should == 45
      t.sec.should == 00
    end
    
    it "should accept (local time) SQL-like yyyy-mm-dd hh:ii datetime strings" do
      t = DateAndTimeUtils.parse_date_or_time('2011-07-13 13:45:21')
      t.should be_a(Time)
      t.day.should == 13
      t.month.should == 07
      t.year.should == 2011
      t.hour.should == 13
      t.min.should == 45
      t.sec.should == 21
    end
    
    it "should accept (local time) Finnish dd.mm.yyyy date strings" do
      d = DateAndTimeUtils.parse_date_or_time('13.07.2011')
      d.should be_a(Date)
      d.day.should == 13
      d.month.should == 07
      d.year.should == 2011
    end
    
    it "should accept (local time) Finnish dd.mm.yyyy hh:ii datetime strings" do
      t = DateAndTimeUtils.parse_date_or_time('13.07.2011 13:45')
      t.day.should == 13
      t.month.should == 07
      t.year.should == 2011
      t.hour.should == 13
      t.min.should == 45
      t.sec.should == 00
    end
    
    it "should accept (local time) Finnish dd.mm.yyyy hh:ii:ss datetime strings" do
      t = DateAndTimeUtils.parse_date_or_time('13.07.2011 13:45:21')
      t.day.should == 13
      t.month.should == 07
      t.year.should == 2011
      t.hour.should == 13
      t.min.should == 45
      t.sec.should == 21
    end
    
    it "should disregard whitespace around the input" do
      t = DateAndTimeUtils.parse_date_or_time(" 13.07.2011 13:45 \n")
      t.day.should == 13
      t.month.should == 07
      t.year.should == 2011
      t.hour.should == 13
      t.min.should == 45
      t.sec.should == 00
    end
    
    it "should raise an exception if it cannot parse the string" do
      expect { DateAndTimeUtils.parse_date_or_time('xooxers') }.to raise_error
      expect { DateAndTimeUtils.parse_date_or_time('2011-07-13 12:34:56:78') }.to raise_error
    end
    
    it "should raise user-friendly exceptions" do
      expect { DateAndTimeUtils.parse_date_or_time('xooxers') }.to raise_error(/Cannot parse .* xooxers/)
      expect { DateAndTimeUtils.parse_date_or_time('2012-99-10') }.to raise_error(/Invalid .* 2012-99-10/)
    end

    it "should accept an SQL-like time with a timezone" do
      t = DateAndTimeUtils.parse_date_or_time('2011-07-13 13:45:21 +0600')
      t.utc.hour.should == 7
    end
  end

  describe "#to_utc_str" do
    it "should format to a full time string with microseconds and timezone" do
      t = DateAndTimeUtils.parse_date_or_time('13.07.2011   14:45:21.123123   +0600')
      t.should == '2011-07-13 14:45:21.123123 +0600'
    end
  end
end

