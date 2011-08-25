require 'fileutils'
require 'capybara'
require 'capybara/dsl'

class DocGen
  include Capybara::DSL
  alias :capybara_page :page
  
  def initialize
    FileUtils.mkdir_p(root_path)
  end
  
  def page(name, &block)
    @page = name
    @file = File.open("#{root_path}/#{name}.html", "wb")
    
    Capybara.using_driver :selenium do
      write_page(name, &block)
    end
  end
  
  def screenshot(options = {})
    rel_img_path = alloc_img
    abs_img_path = "#{root_path}/#{rel_img_path}"
    screenshot_to_file(abs_img_path)
    @file.puts("<img alt=\"(screenshot)\" src=\"#{rel_img_path}\" />")
  end
  
  def paragraph(text = nil, &block)
    if block && text
      raise '#paragraph takes either a string or a block, not both'
    end
    if text
      make_tag "p" do
        self.puts(text)
      end
    else
      make_tag("p", &block)
    end
  end
  
  def puts(s)
    @file.puts(s)
  end
  
  def <<(s)
    @file << s
  end

protected
  def write_page(name, &block)
    @file.puts("<!DOCTYPE html>")
    make_tag("html") do
      make_tag("head") do
        make_tag("title") do
          puts(name.capitalize)
        end
      end
      make_tag("body") do
        block.call
      end
    end
  end

  def make_tag(name, &block)
    if block
      begin
        @file.puts("<#{name}>")
        block.call
      ensure
        @file.puts("</#{name}>")
      end
    else
      @file.puts("<#{name} />")
    end
  end

  def root_path
    "#{Rails::root}/doc/manual"
  end
  
  def relative_img_path
    "img"
  end
  
  def alloc_img
    @img_counter ||= 0
    @img_counter += 1
    "#{relative_img_path}/#{@page}-#{@img_counter}.png"
  end
  
  def screenshot_to_file(file)
    capybara_page.driver.browser.save_screenshot(file)
#    File.open(file, "wb") do |f|
#      f.write(Base64.decode64(page.driver.browser.screenshot_as(:base64)))
#    end
  end
end

