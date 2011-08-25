require 'spec_helper'
require 'capybara/rails'

describe "User manual", :type => :request do
  
  it "has an introduction" do
    doc = DocGen.new("intro")
    doc.page("intro") do
      doc.p("Hello World.")
      
      visit '/'
      doc.screenshot
    end
  end
  
end

