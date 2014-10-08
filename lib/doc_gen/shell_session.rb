require 'cgi' # for escapeHTML

class DocGen
  # A shell session where the interaction can be printed to the generated document.
  class ShellSession
    attr_accessor :prompt
    attr_accessor :working_dir

    def initialize
      @prompt = '$ '
      @working_dir = Dir.pwd
    end

    # Usage:
    # shell.example do |sh|
    #   sh.run "ls"
    # end
    def example(&block)
      example = ExampleBlock.new(self)
      block.call(example)
      '<div class="shell">' + example.transcript + '</div>'
    end

  private
    class ExampleBlock
      attr_reader :transcript

      def initialize(session)
        @session = session
        @transcript = ""
      end

      def blank_line
        @transcript << "<br />"
      end

      def run(command)
        output = nil
        Dir.chdir @session.working_dir do
          output = `#{command} 2>&1`
          if !$?.success?
            error_msg = "Command `#{command}` failed with status #{$?}."
            error_msg << " The output was:\n#{output}" unless output.strip.empty?
            raise error_msg
          end
        end

        prompt_html = CGI::escapeHTML(@session.prompt)
        command_html = CGI::escapeHTML(command)
        output_lines = output.split("\n", -1) # -1 to get empty fields after trailing newlines
        output_html = output_lines.map {|line| CGI::escapeHTML(line) }.join("<br />\n")

        @transcript << "<span class=\"prompt\">#{prompt_html}</span>"
        @transcript << "<span class=\"command\">#{command_html}</span><br />\n"
        @transcript << "<span class=\"output\">#{output_html}</span>"
        nil
      end
    end
  end
end
