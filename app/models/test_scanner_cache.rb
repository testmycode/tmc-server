# Caches results from scanning for tests.
#
# CourseRefresher needs to find the available points in the tests.
# This is a slow operation as it invokes the Java compiler as an annotation processor
# in order to find the @Points annotations. For a large repo, this adds up.
# This class stores a cache of test cases and their available points.
# It is keyed by a hash of the relevant files in an exercise dir.
class TestScannerCache
  def self.get_or_update(course, exercise_name, files_hash, &block)
    entries = course.test_scanner_cache_entries.where(:exercise_name => exercise_name)
    if entries.size == 1
      entry = entries.first
    elsif entries.size == 0
      entry = TestScannerCacheEntry.new(:course => course, :exercise_name => exercise_name)
    else
      raise 'TestScannerCache has a duplicate entry. Uniqueness has not been enforced.'
    end

    if entry.files_hash == files_hash
      decode_value(entry.value)
    else
      entry.value = block.call.to_json
      entry.files_hash = files_hash
      try_save(entry)
      decode_value(entry.value)
    end
  end

  def self.clear!
    TestScannerCacheEntry.delete_all
  end

private
  def self.try_save(entry)
    begin
      entry.save!
    rescue ActiveRecord::RecordNotUnique
      result
    rescue
      ActiveRecord::Base.logger.warn("Failed to add entry to TestScannerCache.")
      ActiveRecord::Base.logger.warn($!)
    end
  end

  def self.decode_value(value)
    JSON.parse(value).each{|element| element.symbolize_keys! }
  end
end
