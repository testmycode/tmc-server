
require 'ruby_init_script'
require 'etc'

namespace :init do
  init_script = RubyInitScript.new({
    :name => 'tmc-submission-reprocessor',
    :short_description => 'TMC submission reprocessor',
    :executable_path => 'script/submission_reprocessor',
    :user => Etc.getpwuid(File.stat(::Rails::root).uid).name
  })

  desc "Install submission reprocessor init script. RVM-compatible."
  task :install do
    init_script.install
  end

  desc "Preview submission reprocessor init script."
  task :preview do
    script = init_script.script_source
    puts
    puts "-"*80
    puts script
    puts "-"*80
    puts
  end

  desc "Uninstall init script."
  task :uninstall do
    init_script.uninstall
  end

  desc "Reinstall init script."
  task :reinstall => [:uninstall, :install]
end
