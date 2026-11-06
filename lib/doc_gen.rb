# typed: strict
# frozen_string_literal: true

require 'fileutils'
require 'erb'
require 'system_commands'

# Used for generating documents from acceptance tests.
# See e.g. spec/usermanual
class DocGen
  extend T::Sig
  # include IntegrationTestActions

  sig { returns(String) }
  attr_reader :doc_name

  # self_in_test: the running RSpec example, which carries the Capybara DSL.
  sig { params(name: String, self_in_test: T.untyped).void }
  def initialize(name, self_in_test)
    @doc_name = name
    @test_case = self_in_test
    @img_counter = T.let(nil, T.nilable(Integer))
  end

  sig { params(template_path: T.any(String, Pathname)).void }
  def render_template(template_path)
    template = File.read(template_path)
    b = send(:binding)
    text = ERB.new(template).result(b)

    FileUtils.mkdir_p(File.dirname(output_path))
    File.open(output_path, 'wb') { |f| f.write(text) }
  end

  sig { params(options: T.untyped).returns(String) }
  def screenshot(options = {})
    name = next_screenshot_name
    screenshot_to_file("#{root_path}/screenshots/#{name}", options)
    '<img src="screenshots/' + name + '" alt="(screenshot)" class="screenshot" />'
  end

  sig { params(matcher: String).returns(T.untyped) }
  def highlight(matcher)
    @test_case.page.execute_script("jQuery('#{matcher}').addClass('highlighted');")
  end

  sig { params(name: Symbol, args: T.untyped, block: T.nilable(Proc)).returns(T.untyped) }
  def method_missing(name, *args, &block)
    @test_case.send(name, *args, &block)
  end

  private
    sig { returns(String) }
    def root_path
      "#{Rails.root}/doc/usermanual"
    end

    sig { returns(String) }
    def output_path
      "#{root_path}/#{@doc_name}.html"
    end

    sig { returns(String) }
    def next_screenshot_name
      @img_counter = (@img_counter || 0) + 1
      "#{@doc_name}-#{@img_counter}.png"
    end

    sig { params(path: T.any(String, Pathname), overrides: T.untyped).returns(T.untyped) }
    def screenshot_to_file(path, overrides)
      default_options = T.let({ full: true }, T::Hash[Symbol, T.untyped])
      options = default_options.merge(overrides)
      FileUtils.mkdir_p(File.dirname(path))
      options[:wide] ? @test_case.page.current_window.resize_to(1200, 800) : @test_case.page.current_window.resize_to(1024, 768)
      @test_case.page.save_screenshot(path, full: options[:full])
    end
end
