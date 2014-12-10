require 'fileutils'

namespace :doc do
  desc "Generate doc/usermanual"
  task usermanual: "doc:usermanual:clean" do
    sh "rspec --tag usermanual spec"
  end
  
  namespace :usermanual do
    desc "Clean doc/usermanual"
    task :clean do
      FileUtils.rm_rf "doc/usermanual/pages"
      FileUtils.rm_rf "doc/usermanual/screenshots"
    end
  end
end
