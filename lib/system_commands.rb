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
    raise "Command `#{cmd}` failed with status #{$?.inspect}" unless ok
  end

  def sh!(*args)
    options = {
      assert_silent: false,
      escape: true,
      timeout: nil
    }
    options = options.merge(args.pop) if args.last.is_a?(Hash)

    if options[:escape]
      cmd = mk_command(args.flatten)
    else
      if args.length == 1
        cmd = args[0]
        cmd = cmd.join(' ') if cmd.is_a?(Array)
      else
        raise 'Expected a single string argument when :escape => true'
      end
    end

    cmd = "timeout #{options[:timeout]} #{cmd}" unless options[:timeout].nil?

    output = `#{cmd} 2>&1`
    status = $?

    raise "Command '#{cmd}' timed out, status #{status.inspect}. The output follows:\n#{output}" if status.exitstatus == 124
    raise "Command `#{cmd}` failed with status #{status.inspect}. The output follows:\n#{output}" unless status.success?
    raise "Expected no output from `#{cmd}` but got: #{output}" if options[:assert_silent] && !output.empty?

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
