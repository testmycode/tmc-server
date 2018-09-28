# frozen_string_literal: true

require 'csv'
begin
  require 'fastercsv'
rescue LoadError
end

# TODO: this should be removed since we no longer support Ruby 1.8
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
