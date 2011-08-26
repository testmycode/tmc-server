require 'fileutils'
require 'capybara'
require 'capybara/dsl'
require 'erb'

class DocGen
  include SystemCommands
  
  attr_reader :doc_name
  
  def initialize(name)
    @doc_name = name
    
    @capybara = Object.new
    class << @capybara
      include Capybara::DSL
    end
  end
  
  def render_template(template_path)
    Capybara.using_driver :selenium do
      @capybara.page.execute_script("window.resizeTo(800, 600);")
      
      template = File.read(template_path)
      b = self.send(:binding)
      text = ERB.new(template).result(b)
      
      FileUtils.mkdir_p(File.dirname(output_path))
      File.open(output_path, "wb") {|f| f.write(text) }
    end
  end
  
  def screenshot(options = {})
    name = next_screenshot_name
    screenshot_to_file("#{root_path}/screenshots/#{name}")
    '<img src="../screenshots/' + name + '" alt="(screenshot)" class="screenshot" />'
  end
  
  def highlight(matcher)
    @capybara.page.execute_script("jQuery('#{matcher}').addClass('highlighted');")
  end
  
  def method_missing(name, *args, &block)
    @capybara.send(name, *args, &block)
  end

protected

  def root_path
    "#{Rails::root}/doc/usermanual"
  end
  
  def output_path
    "#{root_path}/pages/#{@doc_name}.html"
  end
  
  def next_screenshot_name
    @img_counter ||= 0
    @img_counter += 1
    "#{@doc_name}-#{@img_counter}.png"
  end
  
  def screenshot_to_file(path)
    FileUtils.mkdir_p(File.dirname(path))
    @capybara.page.driver.browser.save_screenshot(path)
    trim_image_edges(path)
  end
  
  def trim_image_edges(path)
    cmd = mk_command [
      'convert',
      '-trim',
      path,
      path + ".tmp"
    ]
    cmd2 = mk_command [
      'mv',
      '-f',
      path + ".tmp",
      path
    ]
    
    # todo: could but these in the background, but Ruby 1.8 doesn't have Process.daemon :(
    system!(cmd)
    system!(cmd2)
  end
end

