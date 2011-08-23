module Debug
  def benchmark(name="", &block)
    start_time = Time.now
    begin
      return block.call
    ensure
      end_time = Time.now
      time = end_time - start_time
      puts "TIME #{name}: #{time}"
    end
  end
  
  extend Debug
end
