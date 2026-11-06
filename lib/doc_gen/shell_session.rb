# typed: strict
# frozen_string_literal: true

require 'cgi' # for escapeHTML
require 'doc_gen'

class DocGen
  # A shell session where the interaction can be printed to the generated document.
  class ShellSession
    extend T::Sig
    sig { returns(String) }
    attr_accessor :prompt
    sig { returns(String) }
    attr_accessor :working_dir

    sig { void }
    def initialize
      @prompt = T.let('$ ', String)
      @working_dir = T.let(Dir.pwd, String)
    end

    # Usage:
    # shell.example do |sh|
    #   sh.run "ls"
    # end
    sig { params(blk: T.proc.params(example: ExampleBlock).void).returns(String) }
    def example(&blk)
      example = ExampleBlock.new(self)
      yield(example)
      '<div class="shell">' + example.transcript + '</div>'
    end

    private
      class ExampleBlock
        extend T::Sig
        sig { returns(String) }
        attr_reader :transcript

        sig { params(session: ShellSession).void }
        def initialize(session)
          @session = session
          @transcript = T.let(+'', String)
        end

        sig { returns(String) }
        def blank_line
          @transcript << '<br />'
        end

        sig { params(command: String).void }
        def run(command)
          output = Dir.chdir @session.working_dir do
            command_output = `#{command} 2>&1`
            unless $?.success?
              error_msg = +"Command `#{command}` failed with status #{$?}."
              error_msg << " The output was:\n#{command_output}" unless command_output.strip.empty?
              raise error_msg
            end
            command_output
          end

          prompt_html = CGI.escapeHTML(@session.prompt)
          command_html = CGI.escapeHTML(command)
          output_lines = output.split("\n", -1) # -1 to get empty fields after trailing newlines
          output_html = output_lines.map { |line| CGI.escapeHTML(line) }.join("<br />\n")

          @transcript << "<span class=\"prompt\">#{prompt_html}</span>"
          @transcript << "<span class=\"command\">#{command_html}</span><br />\n"
          @transcript << "<span class=\"output\">#{output_html}</span>"
          nil
        end
      end
  end
end
