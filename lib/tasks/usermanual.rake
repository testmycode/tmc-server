require 'fileutils'

namespace :doc do
  desc "Generate doc/usermanual"
  task :usermanual => "doc:usermanual:clean" do
    sh "rspec spec/usermanual"
  end
  
  namespace :usermanual do
    desc "Clean doc/usermanual"
    task :clean do
      FileUtils.rm_rf "doc/usermanual"
    end
  end
end

