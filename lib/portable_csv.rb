require 'csv'
begin
  require 'fastercsv'
rescue LoadError
end

class PortableCSV
  def self.generate(options = {}, &block)
    csv_engine.generate(options, &block)
  end

private
  def self.csv_engine
    if const_defined?(:CSV) && !CSV.const_defined?(:Reader)
      CSV # Ruby 1.9
    else
      FasterCSV # Ruby 1.8
    end
  end
end