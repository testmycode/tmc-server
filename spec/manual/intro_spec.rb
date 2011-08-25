require 'spec_helper'
require 'capybara/rails'

describe "User manual", :type => :request do
  
  it "Has an introduction" do
    doc = DocGen.new
    doc.page("intro") do
      doc.paragraph("Hello World.")
      
      visit '/'
      doc.screenshot
    end
  end
  
end

