require 'fileutils'
require 'capybara'
require 'capybara/dsl'

class DocGen
  include SystemCommands
  
  attr_reader :doc_name
  
  def initialize(name, options = {})
    if !options[:target]
      FileUtils.mkdir_p(root_path)
      file = File.open("#{root_path}/#{name}.html", "wb")
      ObjectSpace.define_finalizer(self, DocGen.file_closer(file))
      options[:target] = file
    end
    
    options[:indent] = 2 if !options[:indent]
    
    @options = options
    @doc_name = name
    
    @capybara = Object.new
    class << @capybara
      include Capybara::DSL
    end
  end
  
  def page(name, &block)
    begin
      @builder = Builder::XmlMarkup.new(@options)
      Capybara.using_driver :selenium do
        write_page(name, &block)
      end
    ensure
      @builder = nil
    end
  end
  
  def screenshot(options = {})
    rel_img_path = next_img_rel_path
    abs_img_path = "#{root_path}/#{rel_img_path}"
    screenshot_to_file(abs_img_path)
    self.img(:alt => "(screenshot)", :src => rel_img_path)
  end
  
  def method_missing(name, *args, &block)
    if name.to_s.end_with?('!')
      @builder.__send__(name, *args, &block)
    else
      @builder.method_missing(name, *args, &block)
    end
  end

protected
  def self.file_closer(file)
    Proc.new { file.close }
  end

  def write_page(name, &block)
    self.declare!(:DOCTYPE, :html)
    self.html do
      self.head do
        self.meta(:'http-equiv' => 'Content-Type', :content => 'text/html; charset=utf-8')
        self.title(name.capitalize)
      end
      self.body do
        block.call
      end
    end
  end

  def root_path
    "#{Rails::root}/doc/manual"
  end
  
  def img_dir_rel_path
    "img"
  end
  
  def next_img_rel_path
    @img_counter ||= 0
    @img_counter += 1
    "#{img_dir_rel_path}/#{@doc_name}-#{@img_counter}.png"
  end
  
  def screenshot_to_file(file)
    FileUtils.mkdir_p(File.dirname(file))
    @capybara.page.driver.browser.save_screenshot(file)
    trim_image_edges(file)
  end
  
  def trim_image_edges(file)
    cmd = mk_command [
      'convert',
      '-trim',
      file,
      file + ".tmp"
    ]
    system!(cmd)
    FileUtils.mv(file + ".tmp", file)
  end
end

