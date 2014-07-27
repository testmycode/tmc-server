require 'system_commands'
require 'tmc_junit_runner'
require 'tmc_checkstyle_runner'
require 'tmc_comet'

TmcJunitRunner.get.make_rake_tasks(self, 'junit_runner')
TmcCheckstyleRunner.get.make_rake_tasks(self, 'checkstyle_runner')
TmcComet.get.make_rake_tasks(self, 'comet')

namespace :spyware_server do
  spyware_dir = 'ext/tmc-spyware-server'
  task :compile do
    puts "Compiling #{spyware_dir}"
    SystemCommands.sh!('make', '-C', spyware_dir)
  end
  task :recompile => ['spyware_server:clean', 'spyware_server:compile']
  task :clean do
    SystemCommands.sh!('make', '-C', spyware_dir, 'clean')
  end
end

desc "Compile all dependencies except for ext/tmc-sandbox."
task :compile => ['junit_runner:compile','checkstyle_runner:compile', 'comet:compile', 'spyware_server:compile']

desc "Recompile all dependencies except for ext/tmc-sandbox."
task :recompile => ['junit_runner:recompile','checkstyle_runner:recompile', 'comet:recompile', 'spyware_server:recompile']

desc "Clean all dependencies except for ext/tmc-sandbox."
task :clean => ['junit_runner:clean', 'checkstyle_runner:clean', 'comet:clean', 'spyware_server:clean']
