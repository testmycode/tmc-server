require 'fileutils'
require 'erb'
require 'system_commands'

# Used for generating documents from acceptance tests.
# See e.g. spec/usermanual
class DocGen
  include IntegrationTestActions

  attr_reader :doc_name

  def initialize(name, self_in_test)
    @doc_name = name
    @test_case = self_in_test
  end

  def render_template(template_path)
    template = File.read(template_path)
    b = send(:binding)
    text = ERB.new(template).result(b)

    FileUtils.mkdir_p(File.dirname(output_path))
    File.open(output_path, 'wb') { |f| f.write(text) }
  end

  def screenshot(_options = {})
    name = next_screenshot_name
    screenshot_to_file("#{root_path}/screenshots/#{name}")
    '<img src="../screenshots/' + name + '" alt="(screenshot)" class="screenshot" />'
  end

  def highlight(matcher)
    @test_case.page.execute_script("jQuery('#{matcher}').addClass('highlighted');")
  end

  def method_missing(name, *args, &block)
    @test_case.send(name, *args, &block)
  end

  private

  def root_path
    "#{Rails.root}/doc/usermanual"
  end

  def output_path
    "#{root_path}/pages/#{@doc_name}.html"
  end

  def next_screenshot_name
    @img_counter ||= 0
    @img_counter += 1
    "#{@doc_name}-#{@img_counter}.png"
  end
end
