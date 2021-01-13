# frozen_string_literal: true

require 'spec_helper'

describe DateAndTimeUtils do
  describe '#to_time' do
    it 'should parse time strings to time' do
      t = DateAndTimeUtils.to_time('15.07.2011 13:45')
      expect(t).to be_a(Time)
      expect(t.day).to eq(15)
      expect(t.hour).to eq(13)
    end

    it 'should convert dates to local midnight time' do
      t = DateAndTimeUtils.to_time('15.07.2011')
      expect(t).to be_a(Time)
      expect(t.day).to eq(15)
      expect(t.hour).to eq(0o0)
      expect(t.min).to eq(0o0)
    end

    it 'should can convert dates to local end of day time' do
      t = DateAndTimeUtils.to_time('15.07.2011', prefer_end_of_day: true)
      expect(t).to be_a(Time)
      expect(t.day).to eq(15)
      expect(t.hour).to eq(23)
      expect(t.min).to eq(59)

      t = DateAndTimeUtils.to_time('15.07.2011 13:14', prefer_end_of_day: true)
      expect(t.hour).to eq(13)
      expect(t.min).to eq(14)
    end

    it 'should convert blanks to nil' do
      expect(DateAndTimeUtils.to_time(nil)).to be_nil
      expect(DateAndTimeUtils.to_time('')).to be_nil
      expect(DateAndTimeUtils.to_time('   ')).to be_nil
    end
  end

  describe '#parse_date_or_time' do
    it 'should accept (local time) SQL-like yyyy-mm-dd date strings' do
      d = DateAndTimeUtils.parse_date_or_time('2011-07-13')
      expect(d).to be_a(Date)
      expect(d.day).to eq(13)
      expect(d.month).to eq(0o7)
      expect(d.year).to eq(2011)
    end

    it 'should accept (local time) SQL-like yyyy-mm-dd hh:ii datetime strings' do
      t = DateAndTimeUtils.parse_date_or_time('2011-07-13 13:45')
      expect(t).to be_a(Time)
      expect(t.day).to eq(13)
      expect(t.month).to eq(0o7)
      expect(t.year).to eq(2011)
      expect(t.hour).to eq(13)
      expect(t.min).to eq(45)
      expect(t.sec).to eq(0o0)
    end

    it 'should accept (local time) SQL-like yyyy-mm-dd hh:ii datetime strings' do
      t = DateAndTimeUtils.parse_date_or_time('2011-07-13 13:45:21')
      expect(t).to be_a(Time)
      expect(t.day).to eq(13)
      expect(t.month).to eq(0o7)
      expect(t.year).to eq(2011)
      expect(t.hour).to eq(13)
      expect(t.min).to eq(45)
      expect(t.sec).to eq(21)
    end

    it 'should accept (local time) Finnish dd.mm.yyyy date strings' do
      d = DateAndTimeUtils.parse_date_or_time('13.07.2011')
      expect(d).to be_a(Date)
      expect(d.day).to eq(13)
      expect(d.month).to eq(0o7)
      expect(d.year).to eq(2011)
    end

    it 'should accept (local time) Finnish dd.mm.yyyy hh:ii datetime strings' do
      t = DateAndTimeUtils.parse_date_or_time('13.07.2011 13:45')
      expect(t.day).to eq(13)
      expect(t.month).to eq(0o7)
      expect(t.year).to eq(2011)
      expect(t.hour).to eq(13)
      expect(t.min).to eq(45)
      expect(t.sec).to eq(0o0)
    end

    it 'should accept (local time) Finnish dd.mm.yyyy hh:ii:ss datetime strings' do
      t = DateAndTimeUtils.parse_date_or_time('13.07.2011 13:45:21')
      expect(t.day).to eq(13)
      expect(t.month).to eq(0o7)
      expect(t.year).to eq(2011)
      expect(t.hour).to eq(13)
      expect(t.min).to eq(45)
      expect(t.sec).to eq(21)
    end

    it 'should disregard whitespace around the input' do
      t = DateAndTimeUtils.parse_date_or_time(" 13.07.2011 13:45 \n")
      expect(t.day).to eq(13)
      expect(t.month).to eq(0o7)
      expect(t.year).to eq(2011)
      expect(t.hour).to eq(13)
      expect(t.min).to eq(45)
      expect(t.sec).to eq(0o0)
    end

    it 'should raise an exception if it cannot parse the string' do
      expect { DateAndTimeUtils.parse_date_or_time('xooxers') }.to raise_error
      expect { DateAndTimeUtils.parse_date_or_time('2011-07-13 12:34:56:78') }.to raise_error
    end

    it 'should raise user-friendly exceptions' do
      expect { DateAndTimeUtils.parse_date_or_time('xooxers') }.to raise_error(/Cannot parse .* xooxers/)
      expect { DateAndTimeUtils.parse_date_or_time('2012-99-10') }.to raise_error(/Invalid .* 2012-99-10/)
    end

    it 'should accept an SQL-like time with a timezone' do
      t = DateAndTimeUtils.parse_date_or_time('2011-07-13 13:45:21 +0600')
      expect(t.utc.hour).to eq(7)
    end
  end

  describe '#to_utc_str' do
    it 'should format to a full time string with microseconds and timezone' do
      t = DateAndTimeUtils.parse_date_or_time('13.07.2011   14:45:21.123123   +0600')
      expect(t).to eq('2011-07-13 14:45:21.123123 +0600')
    end
  end
end
