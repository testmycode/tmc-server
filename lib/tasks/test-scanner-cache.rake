
namespace :test_scanner_cache do
  desc "Clears the cache of test scanner results. Should be done when upgrading the software."
  task :clear => :environment do
    TestScannerCache.clear!
  end
end

