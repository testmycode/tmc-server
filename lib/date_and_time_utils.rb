
module DateAndTimeUtils
  def self.parse_date_or_time(input)
    s = input.strip
    
    if s =~ /^(\d+)\.(\d+)\.(\d+)(.*)$/
      s = "#{$3}-#{$2}-#{$1}#{$4}"
    end
    
    result = nil
    begin
      if s =~ /^\d+-\d+-\d+$/
        result = Date.parse(s)
      elsif s =~ /^\d+-\d+-\d+\s+\d+:\d+(:?:\d+)?$/
        result = Time.parse(s)
      end
    rescue
      raise "Invalid date/time: #{input}"
    end
    
    raise "Cannot parse date/time: #{input}" if !result
    
    result
  end
end

