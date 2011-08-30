require 'spec_helper'

describe "User manual", :type => :request, :usermanual => true do
  
  before :each do
    # switch from transaction strategy to truncation strategy
    DatabaseCleaner.clean # end the transaction
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  it "has a page for instructors" do
    doc = DocGen.new("instructors", self)
    doc.render_template(File.join(File.dirname(__FILE__), "instructors.html.erb"))
  end
  
end

