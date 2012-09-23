require 'tmc_junit_runner'
require 'fileutils'

TmcJunitRunner.get.make_rake_tasks(self, 'junit_runner')
