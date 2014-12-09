
module DateAndTimeUtils
  def self.to_time(input, options = {})
    options = {
      prefer_end_of_day: false
    }.merge options

    d = input
    if d.blank?
      return nil
    end

    d = self.parse_date_or_time(d) if d.is_a?(String)

    if d.is_a? Date
      if options[:prefer_end_of_day]
        d = d.end_of_day
      else
        d = d.beginning_of_day
      end
    elsif !d.is_a?(Time)
      raise "Invalid date or time: #{input}"
    end
    d
  end

  def self.parse_date_or_time(input)
    s = input.strip

    if s =~ /^(\d+)\.(\d+)\.(\d+)(.*)$/
      s = "#{$3}-#{$2}-#{$1}#{$4}"
    end

    result = nil
    begin
      if s =~ /^\d+-\d+-\d+$/
        result = Date.parse(s)
      elsif s =~ /^\d+-\d+-\d+\s+\d+:\d+(:?:\d+(:?\.\d+)?)?(:?\s+\S+)?$/
        result = Time.zone.parse(s)
      end
    rescue
      raise "Invalid date/time: #{input}"
    end

    raise "Cannot parse date/time: #{input}" if !result

    result
  end

  def self.to_utc_str(time, options = {})
    t = to_time(time, options)
    if t != nil
      t.utc.strftime('%Y-%m-%d %H:%M:%S.%6N %Z')
    else
      t
    end
  end

  def self.looks_like_date_or_time(str)
    begin
      !!parse_date_or_time(str)
    rescue
      false
    end
  end
end

