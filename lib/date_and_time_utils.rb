
# frozen_string_literal: true

module DateAndTimeUtils
  def self.to_time(input, options = {})
    options = {
      prefer_end_of_day: false
    }.merge options

    d = input
    return nil if d.blank?

    d = parse_date_or_time(d) if d.is_a?(String)

    if d.is_a? Date
      d = if options[:prefer_end_of_day]
            d.end_of_day
          else
            d.beginning_of_day
          end
    elsif !d.is_a?(Time)
      raise "Invalid date or time: #{input}"
    end
    d
  end

  def self.parse_date_or_time(input)
    s = input.strip

    s = "#{Regexp.last_match(3)}-#{Regexp.last_match(2)}-#{Regexp.last_match(1)}#{Regexp.last_match(4)}" if s =~ /^(\d+)\.(\d+)\.(\d+)(.*)$/

    result = nil
    begin
      if /^\d+-\d+-\d+$/.match?(s)
        result = Date.parse(s)
      elsif /^\d+-\d+-\d+\s+\d+:\d+(:?:\d+(:?\.\d+)?)?(:?\s+\S+)?$/.match?(s)
        result = Time.zone.parse(s)
      end
    rescue StandardError
      raise "Invalid date/time: #{input}"
    end

    raise "Cannot parse date/time: #{input}" unless result

    result
  end

  def self.to_utc_str(time, options = {})
    t = to_time(time, options)
    if !t.nil?
      t.utc.strftime('%Y-%m-%d %H:%M:%S.%6N %Z')
    else
      t
    end
  end

  def self.looks_like_date_or_time(str)
    !!parse_date_or_time(str)
  rescue StandardError
    false
  end
end
