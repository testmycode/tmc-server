require 'spec_helper'
require 'capybara/rails'

describe "User manual", :type => :request do
  
  it "has an introduction" do
    doc = DocGen.new
    doc.page("intro") do
      doc.paragraph("Hello World.")
      
      visit '/'
      doc.screenshot
    end
  end
  
end

