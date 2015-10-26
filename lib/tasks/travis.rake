require 'system_commands'

namespace :travis do
  desc "Update vendor/bundle files to gem cache on tmc-server"
  task :gemcache do
    puts "Pushing new gems from local gem cache (vendor/bundle) to travis cache"
    SystemCommands.sh!("find vendor/bundle -iname '*.gem'  -print0  | rsync -0 --checksum -avz  --files-from=- . web01:/srv/www/testmycode.net/travis/rubygems-cache/", {escape: false})
    puts "Done"
  end
end

