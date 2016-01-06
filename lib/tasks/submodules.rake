require 'system_commands'
require 'tmc_checkstyle_runner'
require 'tmc_comet'
require 'tmc_langs'

TmcCheckstyleRunner.get.make_rake_tasks(self, 'checkstyle_runner')
TmcComet.get.make_rake_tasks(self, 'comet')
TmcLangs.get.make_rake_tasks(self, 'tmc-langs')

namespace :spyware_server do
  spyware_dir = 'ext/tmc-spyware-server'
  binary = "#{spyware_dir}/cgi-bin/tmc-spyware-server-cgi"
  file binary => FileList["#{spyware_dir}/*.[ch]", "#{spyware_dir}/Makefile"] do
    puts "Compiling #{spyware_dir}"
    SystemCommands.sh!('make', '-C', spyware_dir)
  end
  task compile: binary
  task recompile: ['spyware_server:clean', 'spyware_server:compile']
  task :clean do
    SystemCommands.sh!('make', '-C', spyware_dir, 'clean')
  end
end
task spec: 'spyware_server:compile'

desc "Compile all dependencies except for ext/tmc-sandbox."
task compile: ['checkstyle_runner:compile', 'comet:compile', 'spyware_server:compile', 'tmc-langs:compile']

desc "Recompile all dependencies except for ext/tmc-sandbox."
task recompile: ['checkstyle_runner:recompile', 'comet:recompile', 'spyware_server:recompile', 'tmc-langs:recompile']

desc "Clean all dependencies except for ext/tmc-sandbox."
task clean: ['checkstyle_runner:clean', 'comet:clean', 'spyware_server:clean', 'tmc-langs:clean']
