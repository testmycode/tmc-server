
namespace :sandbox do
  namespace :local do
    
    desc "Starts a local tmc-sandbox server on port 3001"
    task :start do
      Dir.chdir('lib/tmc-sandbox/web') do
        pid = Process.fork do
          ENV.delete('BUNDLE_GEMFILE')
          Process.exec('rackup --server webrick --port 3001')
        end
        Process.waitpid(pid)
      end
    end
    
  end
end
