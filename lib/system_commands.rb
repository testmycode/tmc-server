require 'shellwords'

# Provides useful methods for working with the shell.
#
# Ruby's standard methods "system" and the backtick operator are
# bad at capturing output and errors.
module SystemCommands
  extend self

  # Prefer sh! instead
  def system!(cmd)
    ok = system(cmd)
    fail "Command `#{cmd}` failed with status #{$CHILD_STATUS.inspect}" unless ok
  end

  def sh!(*args)
    options = {
      assert_silent: false,
      escape: true
    }
    if args.last.is_a?(Hash)
      options = args.pop.merge(options)
    end

    if options[:escape]
      cmd = mk_command(args.flatten)
    else
      if args.length == 1
        cmd = args[0]
      else
        fail 'Expected a single string argument when :escape => true'
      end
    end

    output = `#{cmd} 2>&1`
    status = $CHILD_STATUS
    fail "Command `#{cmd}` failed with status #{status.inspect}. The output follows:\n#{output}" unless status.success?
    fail "Expected no output from `#{cmd}` but got: #{output}" if options[:assert_silent] && !output.empty?

    {
      status: status,
      output: output
    }
  end

  def mk_command(*args)
    cmd_parts = args.flatten
    cmd_parts.map { |arg| Shellwords.escape(arg.to_s) }.join(' ')
  end

  def make_bash_array(*args)
    '(' + mk_command(args) + ')'
  end
end
