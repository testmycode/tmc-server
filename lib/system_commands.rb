
module SystemCommands
  def system!(cmd)
    ok = system(cmd)
    raise "Command `#{cmd}` failed with status #{$?}" if !ok
  end
end
