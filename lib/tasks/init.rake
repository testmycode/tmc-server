
require 'ruby_init_script'
require 'etc'

namespace :init do
  DEFAULT_NAME = 'tmc-submission-reprocessor'

  def init_script(name)
    name ||= DEFAULT_NAME
    RubyInitScript.new({
      :name => name,
      :short_description => 'TMC submission reprocessor',
      :executable_path => 'script/submission_reprocessor',
      :user => Etc.getpwuid(File.stat(::Rails::root).uid).name
    })
  end

  desc "Install submission reprocessor init script. RVM-compatible. Optional arg: script name."
  task :install, [:name] do |t, args|
    init_script(args[:name]).install
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

  desc "Uninstall init script. Optional arg: script name."
  task :uninstall, :name do |t, args|
    init_script(args[:name]).uninstall
  end

  desc "Reinstall init script. Optional arg: script name."
  task :reinstall, [:name] => [:uninstall, :install]
end
