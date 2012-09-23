require 'tmc_junit_runner'
require 'tmc_comet'

TmcJunitRunner.get.make_rake_tasks(self, 'junit_runner')
TmcComet.get.make_rake_tasks(self, 'comet')

desc "Compile all dependencies except for ext/tmc-sandbox."
task :compile => ['junit_runner:compile', 'comet:compile']

desc "Recompile all dependencies except for ext/tmc-sandbox."
task :recompile => ['junit_runner:recompile', 'comet:recompile']

desc "Clean all dependencies except for ext/tmc-sandbox."
task :clean => ['junit_runner:clean', 'comet:clean']
