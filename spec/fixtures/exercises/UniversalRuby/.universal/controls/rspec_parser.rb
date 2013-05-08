#!/usr/bin/env ruby
require 'json'

class Spec
  attr_accessor :name, :status, :backtrace, :point_names

  def initialize(name=nil, status=nil, backtrace=nil)
    @name = name
    @status = status
    @backtrace = backtrace
    @point_names = []
  end

  def json_dump
    hash = { 'methodName' => @name, 'backtrace' => @backtrace, 'status' => @status.upcase}
    hash['pointNames'] = @point_names unless @point_names.nil?
    hash
  end

end

class RspecParser
  attr_accessor :specs

  # Context is the root directory of the project, as given when run with .universal/conrols/test
  def parse
    json = `rspec -f j spec/ 2> /dev/null`
    parse_specs(json)
  end

  def parse_specs(json)
    @specs = []
    json = JSON.parse(json)
    json['examples'].each do |example|
      spec = Spec.new("#{example['full_description']}#{example['description']}".gsub(" ", "_"), example['status'])
      spec.backtrace = "#{example['exception']['class']}\n#{example['exception']['message']}\n#{example['exception']['backtrace']}" unless example['exception'].nil?
      @specs << spec
    end
  end

  def parse_points
    spec_file_names = Dir.glob("spec/*")
    spec_file_names.each do |spec_file_name|
      content = File.read(spec_file_name)
      lines = content.split("__END__\n").last.chomp.split("\n")
      0.upto(lines.count - 1) do |i|
        @specs[i].point_names = lines[i].chomp.split(" ") unless @specs[i].nil?
      end
    end
  end

  def dump_only_points
    spec_file_names = Dir.glob("spec/*")
    spec_file_names.each do |spec_file_name|
      content = File.read(spec_file_name)
      lines = content.split("__END__\n").last.chomp.split("\n")
      lines.each do |line|
        puts line
      end
    end
  end

  def dump_points
    @specs.each do |spec|
      spec.point_names.each {|point_name| puts point_name}
    end
  end

  def dump_results
    results = []
    @specs.each do |spec|
      results << spec.json_dump
    end 
    puts JSON.generate results
  end
end

option = ARGV[0] || 'specs'

parser = RspecParser.new
if option == 'specs'
  parser.parse
  parser.parse_points
  parser.dump_results
elsif option == 'points'
  parser.dump_only_points
else
  puts "Error. Invalid option."
end
