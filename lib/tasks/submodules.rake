# frozen_string_literal: true

require 'system_commands'
require 'tmc_langs'

TmcLangs.get.make_rake_tasks(self, 'tmc-langs')

desc 'Compile all dependencies'
task compile: ['tmc-langs:compile']

desc 'Recompile all dependencies'
task recompile: ['tmc-langs:recompile']

desc 'Clean all dependencies'
task clean: ['tmc-langs:clean']
